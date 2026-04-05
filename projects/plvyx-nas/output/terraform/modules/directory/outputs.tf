output "directory_id" {
  description = "Managed AD directory ID."
  value       = aws_directory_service_directory.this.id
}

output "dns_ip_addresses" {
  description = "Managed AD DNS IP addresses."
  value       = aws_directory_service_directory.this.dns_ip_addresses
}

output "security_group_id" {
  description = "AWS-managed security group ID for Managed AD."
  value       = aws_directory_service_directory.this.security_group_id
}
