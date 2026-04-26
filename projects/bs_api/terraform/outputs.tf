output "buildserver_id" {
  description = "EC2 instance ID of the buildserver"
  value       = module.buildserver.id
}

output "buildserver_public_ip" {
  description = "Elastic IP address of the buildserver"
  value       = aws_eip.buildserver.public_ip
}
