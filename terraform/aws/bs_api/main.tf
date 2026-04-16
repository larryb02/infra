terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lkb-main-s3-bucket"
    key            = "bs_api/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "amzlinux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "security_groups" {
  source = "../security_groups"
}

resource "aws_instance" "buildserver" {
  ami                         = data.aws_ami.amzlinux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [module.security_groups.http_server_sg_id]

  tags = {
    Name = "buildserver"
    Role = "buildserver-api"
  }
}

resource "aws_eip" "buildserver" {
  instance = aws_instance.buildserver.id
  domain   = "vpc"

  tags = {
    Name = "buildserver"
  }
}
