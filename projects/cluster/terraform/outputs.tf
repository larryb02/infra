output "server_id" {
  value = module.k3s_server.id
}

output "server_public_ip" {
  value = module.k3s_server.public_ip
}

output "security_groups" {
  value = {
    k3s_server = module.sg_k3s_server.security_group_id
  }
}
