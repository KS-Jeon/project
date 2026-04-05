data "aws_secretsmanager_secret_version" "ad_credentials" {
  secret_id = var.ad_admin_password_secret_arn
}

module "network" {
  source = "../../modules/network"

  name_vpc              = local.names.vpc
  name_route_table      = local.names.route_table
  name_vpn_gateway      = local.names.vpn_gateway
  name_customer_gateway = local.names.customer_gateway
  name_vpn_connection   = local.names.vpn_connection

  vpc_cidr = var.vpc_cidr

  private_subnet_specs       = local.private_subnet_specs
  customer_gateway_bgp_asn   = var.customer_gateway_bgp_asn
  onprem_public_ip           = var.onprem_public_ip
  onprem_cidr                = var.onprem_cidr
  tags                       = local.provider_default_tags
}

module "directory" {
  source = "../../modules/directory"

  directory_domain_name = var.directory_domain_name
  directory_display_name = local.names.managed_ad
  vpc_id                = module.network.vpc_id
  directory_subnet_ids = [
    module.network.private_subnet_ids[1],
    module.network.private_subnet_ids[2],
  ]
  managed_ad_password = local.managed_ad_password
  tags                = local.provider_default_tags
}

module "security" {
  source = "../../modules/security"

  fsx_security_group_name        = local.names.fsx_security_group
  managed_ad_security_group_name = local.names.ad_security_group
  vpc_id                         = module.network.vpc_id
  onprem_cidr                    = var.onprem_cidr
  managed_ad_security_group_id   = module.directory.security_group_id
  tags                           = local.provider_default_tags
}

module "storage" {
  source = "../../modules/storage"

  aws_region                              = var.aws_region
  kms_key_name                            = local.names.kms_key
  fsx_file_system_name                    = local.names.fsx_file_system
  fsx_svm_name                            = local.names.fsx_svm
  fsx_volume_name                         = local.names.fsx_volume
  preferred_subnet_id                     = module.network.private_subnet_ids[0]
  route_table_ids                         = module.network.private_route_table_ids
  fsx_security_group_id                   = module.security.fsx_security_group_id
  fsx_storage_capacity_gib                = var.fsx_storage_capacity_gib
  fsx_throughput_capacity_mbps            = var.fsx_throughput_capacity_mbps
  fsx_backup_retention_days               = var.fsx_backup_retention_days
  fsx_daily_backup_start_time             = var.fsx_daily_backup_start_time
  fsx_weekly_maintenance_start_time       = var.fsx_weekly_maintenance_start_time
  fsx_volume_size_megabytes               = var.fsx_volume_size_megabytes
  directory_domain_name                   = var.directory_domain_name
  managed_ad_dns_ip_addresses             = module.directory.dns_ip_addresses
  ad_netbios_name                         = var.ad_netbios_name
  ad_join_username                        = local.ad_join_username
  managed_ad_password                     = local.managed_ad_password
  ad_delegated_administrators_group       = var.ad_delegated_administrators_group
  ad_organizational_unit_distinguished_name = var.ad_organizational_unit_distinguished_name
  tags                                    = local.provider_default_tags

  depends_on = [module.security]
}

module "observability" {
  source = "../../modules/observability"

  log_group_name                       = "/aws/fsx/ontap"
  log_group_tag_name                   = local.names.fsx_log_group_tag_name
  log_retention_days                   = var.log_retention_days
  fsx_file_system_id                   = module.storage.fsx_file_system_id
  vpn_connection_id                    = module.network.vpn_connection_id
  fsx_capacity_alarm_name              = local.names.fsx_capacity_alarm
  fsx_throughput_alarm_name            = local.names.fsx_throughput_alarm
  vpn_tunnel_alarm_name                = local.names.vpn_tunnel_alarm
  fsx_capacity_alarm_threshold_percent = var.fsx_capacity_alarm_threshold_percent
  fsx_throughput_alarm_threshold_mbps  = var.fsx_throughput_alarm_threshold_mbps
  vpn_tunnel_alarm_period_seconds      = var.vpn_tunnel_alarm_period_seconds
  alarm_actions                        = local.alarm_actions
  tags                                 = local.provider_default_tags
}
