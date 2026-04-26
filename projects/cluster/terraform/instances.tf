module "server" {
  source                 = "../../../modules/ec2-instance"
  instance_type          = var.server_instance_type
  vpc_security_group_ids = [aws_security_group.k3s-server.id]
  name                   = "k3s-server"
  role                   = "server"
  env                    = var.env
}

module "agent" {
  count                  = var.agent_count
  source                 = "../../../modules/ec2-instance"
  instance_type          = var.agent_instance_type
  vpc_security_group_ids = [aws_security_group.k3s-agent.id]
  name                   = "k3s-agent-${count.index}"
  role                   = "agent"
  env                    = var.env
}
