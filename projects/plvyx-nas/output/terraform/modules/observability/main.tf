locals {
  fsx_throughput_alarm_threshold_bytes_per_second = var.fsx_throughput_alarm_threshold_mbps * 1024 * 1024
}

resource "aws_cloudwatch_log_group" "fsx_ontap" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = var.log_group_tag_name
    name = var.log_group_tag_name
  })
}

resource "aws_cloudwatch_metric_alarm" "fsx_capacity" {
  alarm_name                = var.fsx_capacity_alarm_name
  alarm_description         = "FSx ONTAP SSD storage capacity utilization >= ${var.fsx_capacity_alarm_threshold_percent}%"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  threshold                 = var.fsx_capacity_alarm_threshold_percent
  namespace                 = "AWS/FSx"
  metric_name               = "StorageCapacityUtilization"
  statistic                 = "Maximum"
  period                    = 300
  treat_missing_data        = "notBreaching"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.alarm_actions
  insufficient_data_actions = []

  dimensions = {
    FileSystemId = var.fsx_file_system_id
    StorageTier  = "SSD"
  }

  tags = merge(var.tags, {
    Name = var.fsx_capacity_alarm_name
    name = var.fsx_capacity_alarm_name
  })
}

resource "aws_cloudwatch_metric_alarm" "fsx_throughput" {
  alarm_name                = var.fsx_throughput_alarm_name
  alarm_description         = "FSx ONTAP client throughput >= ${var.fsx_throughput_alarm_threshold_mbps} MBps"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  threshold                 = local.fsx_throughput_alarm_threshold_bytes_per_second
  treat_missing_data        = "notBreaching"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.alarm_actions
  insufficient_data_actions = []

  metric_query {
    id          = "m1"
    return_data = false

    metric {
      namespace   = "AWS/FSx"
      metric_name = "DataReadBytes"
      stat        = "Sum"
      period      = 300

      dimensions = {
        FileSystemId = var.fsx_file_system_id
      }
    }
  }

  metric_query {
    id          = "m2"
    return_data = false

    metric {
      namespace   = "AWS/FSx"
      metric_name = "DataWriteBytes"
      stat        = "Sum"
      period      = 300

      dimensions = {
        FileSystemId = var.fsx_file_system_id
      }
    }
  }

  metric_query {
    id          = "e1"
    label       = "ClientThroughputBytesPerSecond"
    expression  = "(m1 + m2) / PERIOD(m1)"
    return_data = true
  }

  tags = merge(var.tags, {
    Name = var.fsx_throughput_alarm_name
    name = var.fsx_throughput_alarm_name
  })
}

resource "aws_cloudwatch_metric_alarm" "vpn_tunnel_down" {
  alarm_name                = var.vpn_tunnel_alarm_name
  alarm_description         = "One or more VPN tunnels are not UP"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  threshold                 = 1
  namespace                 = "AWS/VPN"
  metric_name               = "TunnelState"
  statistic                 = "Minimum"
  period                    = var.vpn_tunnel_alarm_period_seconds
  treat_missing_data        = "breaching"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.alarm_actions
  insufficient_data_actions = []

  dimensions = {
    VpnId = var.vpn_connection_id
  }

  tags = merge(var.tags, {
    Name = var.vpn_tunnel_alarm_name
    name = var.vpn_tunnel_alarm_name
  })
}
