variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "lkb-main-s3-bucket"
}

variable "lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "infra-tf-locks"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format for OIDC trust"
  type        = string
}
