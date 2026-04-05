resource "aws_fsx_ontap_file_system" "this" {
  storage_capacity                   = var.fsx_storage_capacity_gib
  storage_type                       = "SSD"
  deployment_type                    = "SINGLE_AZ_1"
  throughput_capacity                = var.fsx_throughput_capacity_mbps
  preferred_subnet_id                = module.vpc.private_subnets[0]
  subnet_ids                         = [module.vpc.private_subnets[0]]
  route_table_ids                    = module.vpc.private_route_table_ids
  security_group_ids                 = [aws_security_group.fsx.id]
  kms_key_id                         = aws_kms_key.fsx.arn
  automatic_backup_retention_days    = var.fsx_backup_retention_days
  daily_automatic_backup_start_time  = var.fsx_daily_backup_start_time
  weekly_maintenance_start_time      = var.fsx_weekly_maintenance_start_time

  disk_iops_configuration {
    mode = "AUTOMATIC"
  }

  tags = merge(local.provider_default_tags, {
    Name = local.names.fsx_file_system
    name = local.names.fsx_file_system
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "this" {
  file_system_id = aws_fsx_ontap_file_system.this.id
  name           = local.names.fsx_svm

  active_directory_configuration {
    netbios_name = var.ad_netbios_name

    self_managed_active_directory_configuration {
      dns_ips                                = aws_directory_service_directory.managed_ad.dns_ip_addresses
      domain_name                            = var.directory_domain_name
      username                               = local.ad_join_username
      password                               = local.managed_ad_password
      file_system_administrators_group       = var.ad_delegated_administrators_group
      organizational_unit_distinguished_name = var.ad_organizational_unit_distinguished_name
    }
  }

  tags = merge(local.provider_default_tags, {
    Name = local.names.fsx_svm
    name = local.names.fsx_svm
  })

  depends_on = [
    aws_security_group_rule.ad_from_fsx,
  ]

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}

resource "aws_fsx_ontap_volume" "shared" {
  name                       = local.names.fsx_volume
  junction_path              = "/shared"
  size_in_megabytes          = var.fsx_volume_size_megabytes
  security_style             = "NTFS"
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.this.id
  copy_tags_to_backups       = true
  snapshot_policy            = "default"

  tiering_policy {
    name           = "AUTO"
    cooling_period = 31
  }

  tags = merge(local.provider_default_tags, {
    Name = local.names.fsx_volume
    name = local.names.fsx_volume
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
