module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5"

  name = local.names.vpc
  cidr = var.vpc_cidr
  azs  = local.private_subnet_azs

  private_subnets      = local.private_subnet_cidrs
  private_subnet_names = local.private_subnet_names

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw         = false
  enable_nat_gateway = false
  enable_vpn_gateway = true

  tags = local.provider_default_tags

  vpc_tags = merge(local.provider_default_tags, {
    Name = local.names.vpc
    name = local.names.vpc
  })

  private_subnet_tags = local.provider_default_tags

  private_route_table_tags = merge(local.provider_default_tags, {
    Name = local.names.route_table
    name = local.names.route_table
  })

  vpn_gateway_tags = merge(local.provider_default_tags, {
    Name = local.names.vpn_gateway
    name = local.names.vpn_gateway
  })
}

resource "aws_ec2_tag" "private_subnet_name_tags" {
  count = length(local.private_subnet_names)

  resource_id = module.vpc.private_subnets[count.index]
  key         = "name"
  value       = local.private_subnet_names[count.index]
}
