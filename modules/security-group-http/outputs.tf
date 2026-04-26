output "http_server_sg_id" {
  description = "Security group ID for HTTP/HTTPS web servers"
  value       = aws_security_group.http_server.id
}
