variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "server_instance_type" {
  description = "EC2 instance type for server nodes"
  type        = string
  default     = "t2.micro"
}

variable "agent_instance_type" {
  description = "EC2 instance type for agent nodes"
  type = string
  default = "t2.micro"
}

variable "agent_count" {
  description = "Number of k3s agent nodes"
  type        = number
  default     = 2
}

variable "public_key_path" {
  description = "public key path"
  type        = string
}
