############################################
# Provider & Region
############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# Network (Public)
############################################
resource "aws_vpc" "t4" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "t4-vpc" }
}

resource "aws_internet_gateway" "t4" {
  vpc_id = aws_vpc.t4.id
  tags   = { Name = "t4-igw" }
}

resource "aws_subnet" "t4_public" {
  vpc_id                  = aws_vpc.t4.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "t4-public-subnet" }
}

resource "aws_route_table" "t4_public" {
  vpc_id = aws_vpc.t4.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.t4.id
  }

  tags = { Name = "t4-public-rt" }
}

resource "aws_route_table_association" "t4_assoc" {
  subnet_id      = aws_subnet.t4_public.id
  route_table_id = aws_route_table.t4_public.id
}

############################################
# Security Groups
############################################
resource "aws_security_group" "t4_web" {
  name        = "t4-web-sg"
  description = "Allow HTTP/HTTPS only (no SSH)"
  vpc_id      = aws_vpc.t4.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All egress"
  }

  tags = { Name = "t4-web-sg" }
}

resource "aws_security_group" "vpce" {
  name        = "t4-vpce-sg"
  description = "Allow HTTPS from VPC CIDR to interface endpoints"
  vpc_id      = aws_vpc.t4.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.t4.cidr_block]
    description = "VPC to VPCE 443"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All egress"
  }

  tags = { Name = "t4-vpce-sg" }
}

############################################
# VPC Endpoints (SSM / ssmmessages / ec2messages)
############################################
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.t4.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.t4_public.id]
  security_group_ids  = [aws_security_group.vpce.id]
  tags = { Name = "t4-vpce-ssm" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.t4.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.t4_public.id]
  security_group_ids  = [aws_security_group.vpce.id]
  tags = { Name = "t4-vpce-ssmmessages" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.t4.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.t4_public.id]
  security_group_ids  = [aws_security_group.vpce.id]
  tags = { Name = "t4-vpce-ec2messages" }
}

############################################
# AMI (Amazon Linux 2023)
############################################
data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

############################################
# EC2 (SSM-only; ensure agent online)
############################################
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.t4_public.id
  vpc_security_group_ids = [aws_security_group.t4_web.id]

  iam_instance_profile   = "EC2SSMRole"

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf install -y amazon-ssm-agent || true
    systemctl enable amazon-ssm-agent
    systemctl restart amazon-ssm-agent
  EOF

  tags = { Name = "t4-web-ssm-only" }

  depends_on = [
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages
  ]
}
