resource "aws_customer_gateway" "this" {
  bgp_asn    = var.customer_gateway_bgp_asn
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"

  tags = merge(local.provider_default_tags, {
    Name = local.names.customer_gateway
    name = local.names.customer_gateway
  })
}

module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 4.0"

  vpc_id              = module.vpc.vpc_id
  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = aws_customer_gateway.this.id

  local_ipv4_network_cidr  = var.onprem_cidr
  remote_ipv4_network_cidr = var.vpc_cidr

  vpc_subnet_route_table_count = length(module.vpc.private_route_table_ids)
  vpc_subnet_route_table_ids   = module.vpc.private_route_table_ids

  vpn_connection_static_routes_only         = true
  vpn_connection_static_routes_destinations = [var.onprem_cidr]

  tags = merge(local.provider_default_tags, {
    Name = local.names.vpn_connection
    name = local.names.vpn_connection
  })
}
