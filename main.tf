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

data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# Network (Public)
############################################
resource "aws_vpc" "t3" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "t3-vpc" }
}

resource "aws_internet_gateway" "t3" {
  vpc_id = aws_vpc.t3.id
  tags   = { Name = "t3-igw" }
}

resource "aws_subnet" "t3_public" {
  vpc_id                  = aws_vpc.t3.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "t3-public-subnet" }
}

resource "aws_route_table" "t3_public" {
  vpc_id = aws_vpc.t3.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.t3.id
  }
  tags = { Name = "t3-public-rt" }
}

resource "aws_route_table_association" "t3_assoc" {
  subnet_id      = aws_subnet.t3_public.id
  route_table_id = aws_route_table.t3_public.id
}

############################################
# Security Group (HTTP/HTTPS only — no SSH)
############################################
resource "aws_security_group" "t3_web" {
  name        = "t3-web-sg"
  description = "Allow HTTP/HTTPS only (no SSH)"
  vpc_id      = aws_vpc.t3.id

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

  tags = { Name = "t3-web-sg" }
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
# EC2 (via SSM, no SSH)
############################################
resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.t3_public.id
  vpc_security_group_ids = [aws_security_group.t3_web.id]

  iam_instance_profile = "EC2SSMRole"

  tags = { Name = "t3-web-ssm" }
}