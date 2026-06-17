output "server_id" {
  value = module.k8s_control_plane.id
}

output "server_public_ip" {
  value = module.k8s_control_plane.public_ip
}

output "security_groups" {
  value = {
    k3s_server = module.sg_k8s_server.security_group_id
  }
}
