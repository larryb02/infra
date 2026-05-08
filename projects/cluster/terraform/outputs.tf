output "server_id" {
  value = module.k3s_server.id
}

output "server_public_ip" {
  value = module.k3s_server.public_ip
}
