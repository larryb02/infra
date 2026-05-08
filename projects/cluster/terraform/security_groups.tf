module "sg_k3s_server" {
  source  = "terraform-aws-modules/security-group/aws//modules/kubernetes-api"
  version = "~> 5.3"

  name   = "k3s-server-${var.env}"
  vpc_id = data.aws_vpc.default.id

  tags = {
    Env = var.env
  }
}
