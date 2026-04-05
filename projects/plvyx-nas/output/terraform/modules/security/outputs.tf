output "fsx_security_group_id" {
  description = "FSx security group ID."
  value       = aws_security_group.fsx.id
}

output "managed_ad_security_group_id" {
  description = "Managed AD security group ID."
  value       = var.managed_ad_security_group_id
}
