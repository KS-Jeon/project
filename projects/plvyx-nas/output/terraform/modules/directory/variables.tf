variable "directory_domain_name" {
  description = "Managed AD domain name."
  type        = string
}

variable "directory_display_name" {
  description = "Managed AD logical resource name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by Managed AD."
  type        = string
}

variable "directory_subnet_ids" {
  description = "Subnet IDs for Managed AD."
  type        = list(string)
}

variable "managed_ad_password" {
  description = "Managed AD admin password."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
