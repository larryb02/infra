output "server_ip" {
  description = "Public IP of the k3s server node"
  value       = module.server.public_ip
}

output "agent_ips" {
  description = "Public IPs of the k3s agent nodes"
  value       = [for a in module.agent : a.public_ip]
}
