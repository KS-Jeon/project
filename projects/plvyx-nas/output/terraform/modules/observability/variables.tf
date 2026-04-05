variable "log_group_name" {
  description = "CloudWatch Logs group name."
  type        = string
}

variable "log_group_tag_name" {
  description = "Logical name tag for the log group."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention days."
  type        = number
}

variable "fsx_file_system_id" {
  description = "FSx file system ID."
  type        = string
}

variable "vpn_connection_id" {
  description = "VPN connection ID."
  type        = string
}

variable "fsx_capacity_alarm_name" {
  description = "FSx capacity alarm name."
  type        = string
}

variable "fsx_throughput_alarm_name" {
  description = "FSx throughput alarm name."
  type        = string
}

variable "vpn_tunnel_alarm_name" {
  description = "VPN tunnel alarm name."
  type        = string
}

variable "fsx_capacity_alarm_threshold_percent" {
  description = "FSx capacity alarm threshold percent."
  type        = number
}

variable "fsx_throughput_alarm_threshold_mbps" {
  description = "FSx throughput alarm threshold in MBps."
  type        = number
}

variable "vpn_tunnel_alarm_period_seconds" {
  description = "VPN tunnel alarm period in seconds."
  type        = number
}

variable "alarm_actions" {
  description = "SNS actions for alarms."
  type        = list(string)
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
