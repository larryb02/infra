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

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "sg_k8s_server" {
  source  = "terraform-aws-modules/security-group/aws//modules/kubernetes-api"
  version = "~> 5.3"

  name   = "k8s-server-${var.env}"
  vpc_id = data.aws_vpc.default.id

  ingress_cidr_blocks = [data.aws_vpc.default.cidr_block]

  tags = {
    Env = var.env
  }
}

module "k8s_control_plane" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  name                   = "control-plane-${var.env}"
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [module.sg_k8s_server.security_group_id]

  tags = {
    Role = "control-plane"
    Env  = var.env
  }
}

module "k8s_worker" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  for_each = toset(["0", "1"])

  name                   = "control-plane-${each.key}-${var.env}"
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [module.sg_k8s_server.security_group_id]

  tags = {
    Role = "control-plane"
    Env  = var.env
  }
}
