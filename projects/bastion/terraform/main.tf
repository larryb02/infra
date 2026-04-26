terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "bastion" {
  source                 = "../../../modules/ec2-instance"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.bastion.id]
  name                   = "bastion"
  role                   = "bastion-host"
  env                    = var.env
}
