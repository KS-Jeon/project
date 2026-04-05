locals {
  project_id   = "plvyx-nas"
  environment  = "prod"
  version_date = var.version_tag

  names = {
    vpc                    = "plvyx-nas-prod-vpc"
    subnet_private_a       = "plvyx-nas-prod-vpc-subnet-private-a"
    subnet_private_b       = "plvyx-nas-prod-vpc-subnet-private-b"
    subnet_private_c       = "plvyx-nas-prod-vpc-subnet-private-c"
    route_table            = "plvyx-nas-prod-vpc-rt"
    vpn_gateway            = "plvyx-nas-prod-vpn-vgw"
    customer_gateway       = "plvyx-nas-prod-vpn-cgw"
    vpn_connection         = "plvyx-nas-prod-vpn-s2s"
    managed_ad             = "plvyx-nas-prod-managed-ad"
    fsx_file_system        = "plvyx-nas-prod-fsx-ontap"
    fsx_svm                = "plvyx-nas-prod-fsx-svm"
    fsx_volume             = "plvyx-nas-prod-fsx-vol"
    fsx_security_group     = "plvyx-nas-prod-sg-fsx"
    ad_security_group      = "plvyx-nas-prod-sg-ad"
    kms_key                = "plvyx-nas-prod-kms-fsx"
    fsx_capacity_alarm     = "plvyx-nas-prod-fsx-capacity-alarm"
    fsx_throughput_alarm   = "plvyx-nas-prod-fsx-throughput-alarm"
    vpn_tunnel_alarm       = "plvyx-nas-prod-vpn-tunnel-alarm"
    fsx_log_group_tag_name = "plvyx-nas-prod-fsx-log"
  }

  provider_default_tags = {
    env     = local.environment
    creator = var.creator
    version = local.version_date
    project = local.project_id
  }

  private_subnet_specs = [
    {
      name = local.names.subnet_private_a
      cidr = "10.100.10.0/24"
      az   = "ap-northeast-2a"
    },
    {
      name = local.names.subnet_private_b
      cidr = "10.100.11.0/24"
      az   = "ap-northeast-2a"
    },
    {
      name = local.names.subnet_private_c
      cidr = "10.100.12.0/24"
      az   = "ap-northeast-2c"
    },
  ]

  private_subnet_names = [for subnet in local.private_subnet_specs : subnet.name]
  private_subnet_cidrs = [for subnet in local.private_subnet_specs : subnet.cidr]
  private_subnet_azs   = [for subnet in local.private_subnet_specs : subnet.az]

  ad_secret_raw  = data.aws_secretsmanager_secret_version.ad_credentials.secret_string
  ad_secret_json = try(jsondecode(local.ad_secret_raw), {})

  managed_ad_password = lookup(
    local.ad_secret_json,
    "CUSTOMER_MANAGED_ACTIVE_DIRECTORY_PASSWORD",
    local.ad_secret_raw
  )

  ad_join_username = lookup(
    local.ad_secret_json,
    "CUSTOMER_MANAGED_ACTIVE_DIRECTORY_USERNAME",
    "Admin"
  )

  alarm_actions = var.cloudwatch_sns_topic_arn == null ? [] : [var.cloudwatch_sns_topic_arn]

  fsx_throughput_alarm_threshold_bytes_per_second = var.fsx_throughput_alarm_threshold_mbps * 1024 * 1024

  ad_ingress_rules = {
    dns_tcp = {
      from_port = 53
      to_port   = 53
      protocol  = "tcp"
    }
    dns_udp = {
      from_port = 53
      to_port   = 53
      protocol  = "udp"
    }
    kerberos_tcp = {
      from_port = 88
      to_port   = 88
      protocol  = "tcp"
    }
    kerberos_udp = {
      from_port = 88
      to_port   = 88
      protocol  = "udp"
    }
    ldap_tcp = {
      from_port = 389
      to_port   = 389
      protocol  = "tcp"
    }
    ldap_udp = {
      from_port = 389
      to_port   = 389
      protocol  = "udp"
    }
    ldaps_tcp = {
      from_port = 636
      to_port   = 636
      protocol  = "tcp"
    }
    smb_tcp = {
      from_port = 445
      to_port   = 445
      protocol  = "tcp"
    }
    rpc_tcp = {
      from_port = 135
      to_port   = 135
      protocol  = "tcp"
    }
    dynamic_rpc_tcp = {
      from_port = 49152
      to_port   = 65535
      protocol  = "tcp"
    }
  }
}
