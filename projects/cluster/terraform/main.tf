terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>= 6.37"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

data "aws_security_group" "k3s_server" {
  name = "k3s-server"
}

module "k3s_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  name                   = "k3s-server-${var.env}"
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.k3s_server.id]

  tags = {
    Role = "k3s-server"
    Env  = var.env
  }
}
