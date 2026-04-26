terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "http_server" {
  name        = "http-server"
  description = "HTTP/HTTPS web server"

  tags = {
    Name = "http-server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_server_allow_http_ipv4" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http_server_allow_http_ipv6" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http_server_allow_https_ipv4" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http_server_allow_https_ipv6" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "http_server_allow_all_ipv4" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "http_server_allow_all_ipv6" {
  security_group_id = aws_security_group.http_server.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
