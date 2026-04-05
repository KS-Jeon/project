variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "kms_key_name" {
  description = "KMS key logical name."
  type        = string
}

variable "fsx_file_system_name" {
  description = "FSx file system name."
  type        = string
}

variable "fsx_svm_name" {
  description = "FSx SVM name."
  type        = string
}

variable "fsx_volume_name" {
  description = "FSx volume name."
  type        = string
}

variable "preferred_subnet_id" {
  description = "Preferred subnet ID for Single-AZ FSx."
  type        = string
}

variable "route_table_ids" {
  description = "Route table IDs attached to FSx."
  type        = list(string)
}

variable "fsx_security_group_id" {
  description = "Security group ID attached to FSx."
  type        = string
}

variable "fsx_storage_capacity_gib" {
  description = "FSx SSD capacity in GiB."
  type        = number
}

variable "fsx_throughput_capacity_mbps" {
  description = "FSx throughput capacity in MBps."
  type        = number
}

variable "fsx_backup_retention_days" {
  description = "FSx automatic backup retention days."
  type        = number
}

variable "fsx_daily_backup_start_time" {
  description = "FSx daily backup start time."
  type        = string
}

variable "fsx_weekly_maintenance_start_time" {
  description = "FSx weekly maintenance start time."
  type        = string
}

variable "fsx_volume_size_megabytes" {
  description = "FSx volume size in MiB."
  type        = number
}

variable "directory_domain_name" {
  description = "Directory domain name."
  type        = string
}

variable "managed_ad_dns_ip_addresses" {
  description = "Managed AD DNS IP addresses."
  type        = list(string)
}

variable "ad_netbios_name" {
  description = "NetBIOS name used by FSx."
  type        = string
}

variable "ad_join_username" {
  description = "AD join service account username."
  type        = string
}

variable "managed_ad_password" {
  description = "Managed AD password used for domain join."
  type        = string
  sensitive   = true
}

variable "ad_delegated_administrators_group" {
  description = "Delegated administrators group name."
  type        = string
}

variable "ad_organizational_unit_distinguished_name" {
  description = "OU distinguished name for the SVM computer object."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
