# Output custom VPC ID
output "vpc_id" {
  description = "ID of the custom VPC"
  value       = aws_vpc.custom_vpc.id
}

# Output public subnet ID
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

# Output security group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}

# Output internet gateway ID
output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}

# Output route table ID
output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

# Output availability zone used
output "availability_zone" {
  description = "Availability zone where resources are deployed"
  value       = data.aws_availability_zones.available.names[0]
}

# Output security group details for verification
output "security_group_details" {
  description = "Detailed information about the security group"
  value = {
    name        = aws_security_group.web_sg.name
    description = aws_security_group.web_sg.description
    vpc_id      = aws_security_group.web_sg.vpc_id
  }
}

# Output CIDR blocks for reference
output "network_cidr_blocks" {
  description = "CIDR blocks used in the network setup"
  value = {
    vpc_cidr    = aws_vpc.custom_vpc.cidr_block
    subnet_cidr = aws_subnet.public_subnet.cidr_block
  }
}