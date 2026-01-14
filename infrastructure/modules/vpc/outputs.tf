output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs de las subnets privadas (app tier)"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "IDs de las subnets privadas (data tier)"
  value       = aws_subnet.private_data[*].id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_instance_id" {
  description = "ID de la NAT Instance"
  value       = var.enable_nat_instance ? aws_instance.nat[0].id : null
}

output "nat_instance_private_ip" {
  description = "IP privada de la NAT Instance"
  value       = var.enable_nat_instance ? aws_instance.nat[0].private_ip : null
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "public_route_table_id" {
  description = "ID de la route table pública"
  value       = aws_route_table.public.id
}

output "private_app_route_table_id" {
  description = "ID de la route table privada (app)"
  value       = aws_route_table.private_app.id
}

output "private_data_route_table_id" {
  description = "ID de la route table privada (data)"
  value       = aws_route_table.private_data.id
}
