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

variable "control_plane_instance_type" {
  description = "EC2 instance type for the Kubernetes control plane node(s)"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for the Kubernetes worker node(s)"
  type        = string
  default     = "t3.small"
}

variable "talos_version" {
  description = "Talos Linux release tag used to resolve the AWS AMI"
  type        = string
  default     = "v1.13.4"
}

variable "talos_arch" {
  description = "CPU architecture for the Talos AMI (amd64 or arm64)"
  type        = string
  default     = "amd64"
}

variable "node_disk_size" {
  description = "Root EBS volume size in GB for each node (gp3)"
  type        = number
  default     = 20
}
