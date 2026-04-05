data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "fsx" {
  description             = var.kms_key_name
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAccountAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowFSxServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = "fsx.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ListGrants",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "fsx.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name = var.kms_key_name
    name = var.kms_key_name
  })
}

resource "aws_kms_alias" "fsx" {
  name          = "alias/${var.kms_key_name}"
  target_key_id = aws_kms_key.fsx.key_id
}

resource "aws_fsx_ontap_file_system" "this" {
  storage_capacity                  = var.fsx_storage_capacity_gib
  storage_type                      = "SSD"
  deployment_type                   = "SINGLE_AZ_1"
  throughput_capacity               = var.fsx_throughput_capacity_mbps
  preferred_subnet_id               = var.preferred_subnet_id
  subnet_ids                        = [var.preferred_subnet_id]
  route_table_ids                   = var.route_table_ids
  security_group_ids                = [var.fsx_security_group_id]
  kms_key_id                        = aws_kms_key.fsx.arn
  automatic_backup_retention_days   = var.fsx_backup_retention_days
  daily_automatic_backup_start_time = var.fsx_daily_backup_start_time
  weekly_maintenance_start_time     = var.fsx_weekly_maintenance_start_time

  disk_iops_configuration {
    mode = "AUTOMATIC"
  }

  tags = merge(var.tags, {
    Name = var.fsx_file_system_name
    name = var.fsx_file_system_name
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "this" {
  file_system_id = aws_fsx_ontap_file_system.this.id
  name           = var.fsx_svm_name

  active_directory_configuration {
    netbios_name = var.ad_netbios_name

    self_managed_active_directory_configuration {
      dns_ips                                = var.managed_ad_dns_ip_addresses
      domain_name                            = var.directory_domain_name
      username                               = var.ad_join_username
      password                               = var.managed_ad_password
      file_system_administrators_group       = var.ad_delegated_administrators_group
      organizational_unit_distinguished_name = var.ad_organizational_unit_distinguished_name
    }
  }

  tags = merge(var.tags, {
    Name = var.fsx_svm_name
    name = var.fsx_svm_name
  })

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}

resource "aws_fsx_ontap_volume" "shared" {
  name                       = var.fsx_volume_name
  junction_path              = "/shared"
  size_in_megabytes          = var.fsx_volume_size_megabytes
  security_style             = "MIXED"
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.this.id
  copy_tags_to_backups       = true
  snapshot_policy            = "default"

  tiering_policy {
    name           = "AUTO"
    cooling_period = 31
  }

  tags = merge(var.tags, {
    Name = var.fsx_volume_name
    name = var.fsx_volume_name
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
