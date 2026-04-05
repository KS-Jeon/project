locals {
  private_subnet_names = [for subnet in var.private_subnet_specs : subnet.name]
  private_subnet_cidrs = [for subnet in var.private_subnet_specs : subnet.cidr]
  private_subnet_azs   = [for subnet in var.private_subnet_specs : subnet.az]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5"

  name = var.name_vpc
  cidr = var.vpc_cidr
  azs  = local.private_subnet_azs

  private_subnets      = local.private_subnet_cidrs
  private_subnet_names = local.private_subnet_names

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw         = false
  enable_nat_gateway = false
  enable_vpn_gateway = true

  tags = var.tags

  vpc_tags = merge(var.tags, {
    Name = var.name_vpc
    name = var.name_vpc
  })

  private_subnet_tags = var.tags

  private_route_table_tags = merge(var.tags, {
    Name = var.name_route_table
    name = var.name_route_table
  })

  vpn_gateway_tags = merge(var.tags, {
    Name = var.name_vpn_gateway
    name = var.name_vpn_gateway
  })
}

resource "aws_ec2_tag" "private_subnet_name_tags" {
  count = length(local.private_subnet_names)

  resource_id = module.vpc.private_subnets[count.index]
  key         = "name"
  value       = local.private_subnet_names[count.index]
}

resource "aws_customer_gateway" "this" {
  bgp_asn    = var.customer_gateway_bgp_asn
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = var.name_customer_gateway
    name = var.name_customer_gateway
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

  tags = merge(var.tags, {
    Name = var.name_vpn_connection
    name = var.name_vpn_connection
  })
}
