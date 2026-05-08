variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type for the K3S server"
  type        = string
  default     = "t3.medium"
}
