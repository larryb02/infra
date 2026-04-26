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

module "security_group" {
  source = "../../../modules/security-group-http"
}

module "buildserver" {
  source                 = "../../../modules/ec2-instance"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.security_group.http_server_sg_id]
  name                   = "buildserver"
  role                   = "buildserver-api"
  env                    = var.env
}

resource "aws_eip" "buildserver" {
  instance = module.buildserver.id
  domain   = "vpc"

  tags = {
    Name = "buildserver"
    Env  = var.env
  }
}
