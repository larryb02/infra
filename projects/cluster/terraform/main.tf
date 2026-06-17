terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
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

# 1. Fetch all subnets in the region that are marked as the default for their AZ
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

module "sg_k8s_control_plane" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name   = "k8s-control-plane"
  vpc_id = data.aws_vpc.default.id

  # Self-referencing (same control plane SG): kubelet, scheduler,
  # controller-manager, and etcd peer/client traffic.
  ingress_with_self = [
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
    # etcd will probably run on a separate node; until it has its own SG,
    # allow the client/peer API within the control plane SG.
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client API (kube-apiserver, etcd)"
    },
  ]

  # API server is reachable by "All" — scope to the VPC CIDR (internal-only)
  # so worker nodes and in-VPC kubectl can reach it.
  ingress_with_cidr_blocks = [
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

  # Worker-to-worker (self-referencing SG)
  ingress_with_self = [
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API (self)"
    },
    {
      from_port   = 10256
      to_port     = 10256
      protocol    = "tcp"
      description = "kube-proxy (self)"
    },
  ]

  # Control plane -> worker (SG-to-SG)
  ingress_with_source_security_group_id = [
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      description              = "Kubelet API (control plane)"
      source_security_group_id = module.sg_k8s_control_plane.security_group_id
    },
  ]

  # Sources without a dedicated SG: NodePort "All" and kube-proxy load
  # balancers, scoped to the VPC CIDR (internal-only).
  ingress_with_cidr_blocks = [
    {
      from_port   = 10256
      to_port     = 10256
      protocol    = "tcp"
      description = "kube-proxy (load balancers)"
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort Services TCP"
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "udp"
      description = "NodePort Services UDP"
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
  ]

  egress_rules = ["all-all"]
}

module "k8s_control_plane" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  name                   = "control-plane-${var.env}"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.sg_k8s_control_plane.security_group_id]
  subnet_id = data.aws_subnets.default.ids[0]

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
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.sg_k8s_worker.security_group_id]
  subnet_id = data.aws_subnets.default.ids[0]

  tags = {
    Role = "worker"
    Env  = var.env
  }
}
