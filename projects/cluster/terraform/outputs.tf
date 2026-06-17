output "server_id" {
  value = module.k8s_control_plane.id
}

output "server_public_ip" {
  value = module.k8s_control_plane.public_ip
}

output "security_groups" {
  value = {
    control_plane = module.sg_k8s_control_plane.security_group_id
    worker        = module.sg_k8s_worker.security_group_id
  }
}
