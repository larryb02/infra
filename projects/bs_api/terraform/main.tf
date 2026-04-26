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

data "aws_security_group" "http_server" {
  name = "http-server"
}

module "buildserver" {
  source                 = "../../../modules/ec2-instance"
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.http_server.id]
  name                   = "${var.env}-buildserver"
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
