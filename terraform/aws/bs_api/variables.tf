variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "instance_type" {
  description = "EC2 instance type for server nodes"
  type        = string
  default     = "t2.micro"
}
