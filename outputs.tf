# Output VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.t4.id
}

# Output public subnet ID
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.t4_public.id
}

# Output security group ID
output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

# Output internet gateway ID
output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.t4.id
}

# Output route table ID
output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.t4_public.id
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
    name        = aws_security_group.web.name
    description = aws_security_group.web.description
    vpc_id      = aws_security_group.web.vpc_id
  }
}

# Output CIDR blocks for reference
output "network_cidr_blocks" {
  description = "CIDR blocks used in the network setup"
  value = {
    vpc_cidr    = aws_vpc.t4.cidr_block
    subnet_cidr = aws_subnet.t4_public.cidr_block
  }
}
