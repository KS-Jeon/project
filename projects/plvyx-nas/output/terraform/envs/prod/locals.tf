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
}
