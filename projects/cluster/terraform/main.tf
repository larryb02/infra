terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

locals {
  # Every distinct instance type the cluster runs. As new roles are added
  # (etcd, load balancer, etc.) include their types here so each gets its own
  # AZ-aware subnet lookup below.
  instance_types = toset([
    var.control_plane_instance_type,
    var.worker_instance_type,
  ])

  # Resolve the official Talos AWS AMI for this region/arch from the release
  # manifest instead of hardcoding a (region-specific, soon-stale) AMI ID.
  # one() errors if the manifest yields more than one match, and returns null
  # on zero matches so a bad region/version/arch fails loud at apply.
  talos_ami = one([
    for img in jsondecode(data.http.talos_cloud_images.response_body) :
    img.id
    if img.region == var.region && img.arch == var.talos_arch
  ])
}

# Official Talos cloud image manifest for the pinned release. Maps each
# region/arch to its published AMI ID.
data "http" "talos_cloud_images" {
  url = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/cloud-images.json"
}

# AZs in this region that actually offer each requested instance type.
data "aws_ec2_instance_type_offerings" "supported" {
  for_each = local.instance_types

  filter {
    name   = "instance-type"
    values = [each.value]
  }

  location_type = "availability-zone"
}

# Default subnets per instance type, restricted to AZs that support that type,
# so each role lands in an AZ that offers its instance type (e.g. t3.medium is
# not offered in us-east-1e). Nodes of different types may end up in different
# AZs. Set keys equal their value, so this is indexed by the instance type.
data "aws_subnets" "by_instance_type" {
  for_each = local.instance_types

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.supported[each.key].locations
  }
}

# Base security groups are created with only self-referencing and operator
# (CIDR) rules. The cross-group rules — where the control plane and workers
# reference each other's SG — would form a dependency cycle if declared inline,
# so they are injected afterward via the `create_sg = false` rule-only modules
# below. Each base SG depends on neither other SG; each cross-rule module
# depends on both, breaking the loop.
module "sg_k8s_control_plane" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name   = "k8s-control-plane"
  vpc_id = data.aws_vpc.default.id

  # Self-referencing (control plane to control plane, for future multi-CP):
  # etcd, kubelet, scheduler, controller-manager, flannel VXLAN.
  ingress_with_self = [
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client/peer API"
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API (self, control plane)"
    },
    {
      from_port   = 10259
      to_port     = 10259
      protocol    = "tcp"
      description = "kube-scheduler (self)"
    },
    {
      from_port   = 10257
      to_port     = 10257
      protocol    = "tcp"
      description = "kube-controller-manager (self)"
    },
    {
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      description = "flannel VXLAN (self)"
    },
  ]

  # Operator access from in-VPC infra (talosctl/kubectl). Worker -> control
  # plane traffic is granted by sg_k8s_control_plane_cross_rules below, not
  # here, so this base SG holds no reference to the worker SG.
  ingress_with_cidr_blocks = [
    {
      from_port   = 50000
      to_port     = 50000
      protocol    = "tcp"
      description = "Talos apid (talosctl)"
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "Kubernetes API server"
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
  ]

  egress_rules = ["all-all"]
}

module "sg_k8s_worker" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name   = "k8s-worker"
  vpc_id = data.aws_vpc.default.id

  # Worker-to-worker (self-referencing SG): flannel VXLAN for cross-worker pod
  # traffic.
  ingress_with_self = [
    {
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      description = "flannel VXLAN (self)"
    },
  ]

  egress_rules = ["all-all"]
}

# Rules injected INTO the control plane SG, sourced from the worker SG. Created
# as a rules-only module (create_sg = false) so it can reference both SGs
# without the control plane SG depending on the worker SG at creation time.
module "sg_k8s_control_plane_cross_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  create_sg         = false
  security_group_id = module.sg_k8s_control_plane.security_group_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 50001
      to_port                  = 50001
      protocol                 = "tcp"
      description              = "Talos trustd (cert issuance to workers)"
      source_security_group_id = module.sg_k8s_worker.security_group_id
    },
    {
      from_port                = 6443
      to_port                  = 6443
      protocol                 = "tcp"
      description              = "Kubernetes API server (from workers)"
      source_security_group_id = module.sg_k8s_worker.security_group_id
    },
    {
      from_port                = 4789
      to_port                  = 4789
      protocol                 = "udp"
      description              = "flannel VXLAN (from workers)"
      source_security_group_id = module.sg_k8s_worker.security_group_id
    },
  ]
}

# Rules injected INTO the worker SG, sourced from the control plane SG.
module "sg_k8s_worker_cross_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  create_sg         = false
  security_group_id = module.sg_k8s_worker.security_group_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 50000
      to_port                  = 50000
      protocol                 = "tcp"
      description              = "Talos apid (from control plane)"
      source_security_group_id = module.sg_k8s_control_plane.security_group_id
    },
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      description              = "Kubelet API (from control plane)"
      source_security_group_id = module.sg_k8s_control_plane.security_group_id
    },
    {
      from_port                = 4789
      to_port                  = 4789
      protocol                 = "udp"
      description              = "flannel VXLAN (from control plane)"
      source_security_group_id = module.sg_k8s_control_plane.security_group_id
    },
  ]
}

module "k8s_control_plane" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  name                   = "control-plane-${var.env}"
  ami                    = local.talos_ami
  instance_type          = var.control_plane_instance_type
  vpc_security_group_ids = [module.sg_k8s_control_plane.security_group_id]
  subnet_id              = data.aws_subnets.by_instance_type[var.control_plane_instance_type].ids[0]

  # Talos machine config delivered as user-data. Generated by `talosctl gen
  # config`; keep controlplane.yaml out of git (contains cluster secrets).
  user_data                   = file("${path.module}/controlplane.yaml")
  user_data_replace_on_change = true

  root_block_device = {
    size = var.node_disk_size
    type = "gp3"
  }

  tags = {
    Role = "control-plane"
    Env  = var.env
  }
}

module "k8s_worker" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  for_each = toset(["0", "1"])

  name                   = "worker-${each.key}-${var.env}"
  ami                    = local.talos_ami
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [module.sg_k8s_worker.security_group_id]
  subnet_id              = data.aws_subnets.by_instance_type[var.worker_instance_type].ids[0]

  # Talos machine config delivered as user-data. Generated by `talosctl gen
  # config`; keep worker.yaml out of git.
  user_data                   = file("${path.module}/worker.yaml")
  user_data_replace_on_change = true

  root_block_device = {
    size = var.node_disk_size
    type = "gp3"
  }

  tags = {
    Role = "worker"
    Env  = var.env
  }
}
