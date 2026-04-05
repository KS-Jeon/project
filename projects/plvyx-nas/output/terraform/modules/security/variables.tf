variable "fsx_security_group_name" {
  description = "FSx security group name."
  type        = string
}

variable "managed_ad_security_group_name" {
  description = "Managed AD security group logical name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "onprem_cidr" {
  description = "On-premises internal CIDR."
  type        = string
}

variable "managed_ad_security_group_id" {
  description = "AWS-managed security group ID for the directory."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
