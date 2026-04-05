output "vpc_id" {
  description = "생성된 VPC ID."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "생성된 private subnet ID 목록."
  value       = module.network.private_subnet_ids
}

output "private_route_table_ids" {
  description = "VPN route propagation이 연결된 private route table ID 목록."
  value       = module.network.private_route_table_ids
}

output "customer_gateway_id" {
  description = "온프레미스 Customer Gateway ID."
  value       = module.network.customer_gateway_id
}

output "vpn_connection_id" {
  description = "AWS Site-to-Site VPN 연결 ID."
  value       = module.network.vpn_connection_id
}

output "vpn_tunnel_addresses" {
  description = "AWS 측 VPN 터널 공인 IP 주소 목록."
  value       = module.network.vpn_tunnel_addresses
}

output "managed_ad_id" {
  description = "Managed Microsoft AD 디렉터리 ID."
  value       = module.directory.directory_id
}

output "managed_ad_dns_ip_addresses" {
  description = "Managed Microsoft AD DNS IP 주소 목록."
  value       = module.directory.dns_ip_addresses
}

output "managed_ad_security_group_id" {
  description = "AWS Directory Service가 생성한 AD 보안 그룹 ID."
  value       = module.directory.security_group_id
}

output "fsx_file_system_id" {
  description = "FSx ONTAP 파일 시스템 ID."
  value       = module.storage.fsx_file_system_id
}

output "fsx_storage_virtual_machine_id" {
  description = "FSx ONTAP SVM ID."
  value       = module.storage.fsx_storage_virtual_machine_id
}

output "fsx_volume_id" {
  description = "공유 볼륨 ID."
  value       = module.storage.fsx_volume_id
}

output "kms_key_arn" {
  description = "FSx 암호화용 KMS Key ARN."
  value       = module.storage.kms_key_arn
}

output "fsx_log_group_name" {
  description = "FSx 운영 로그용 CloudWatch Logs 그룹 이름."
  value       = module.observability.log_group_name
}
