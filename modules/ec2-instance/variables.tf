variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
}

variable "name" {
  description = "Value for the Name tag"
  type        = string
}

variable "role" {
  description = "Value for the Role tag"
  type        = string
}

variable "env" {
  description = "Deployment environment (prod, dev, etc.)"
  type        = string
  default     = "prod"
}
