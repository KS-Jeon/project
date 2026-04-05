output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = module.vpc.private_route_table_ids
}

output "customer_gateway_id" {
  description = "Customer gateway ID."
  value       = aws_customer_gateway.this.id
}

output "vpn_connection_id" {
  description = "VPN connection ID."
  value       = module.vpn_gateway.vpn_connection_id[0]
}

output "vpn_tunnel_addresses" {
  description = "VPN tunnel public addresses."
  value = [
    module.vpn_gateway.vpn_connection_tunnel1_address[0],
    module.vpn_gateway.vpn_connection_tunnel2_address[0],
  ]
}
