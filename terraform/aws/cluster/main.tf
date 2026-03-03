terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lkb-main-s3-bucket"
    key            = "cluster/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
