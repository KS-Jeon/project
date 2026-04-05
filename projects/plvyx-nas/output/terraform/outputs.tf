output "vpc_id" {
  description = "생성된 VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "생성된 private subnet ID 목록."
  value       = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "VPN route propagation이 연결된 private route table ID 목록."
  value       = module.vpc.private_route_table_ids
}

output "customer_gateway_id" {
  description = "온프레미스 Customer Gateway ID."
  value       = aws_customer_gateway.this.id
}

output "vpn_connection_id" {
  description = "AWS Site-to-Site VPN 연결 ID."
  value       = module.vpn_gateway.vpn_connection_id[0]
}

output "vpn_tunnel_addresses" {
  description = "AWS 측 VPN 터널 공인 IP 주소 목록."
  value = [
    module.vpn_gateway.vpn_connection_tunnel1_address[0],
    module.vpn_gateway.vpn_connection_tunnel2_address[0],
  ]
}

output "managed_ad_id" {
  description = "Managed Microsoft AD 디렉터리 ID."
  value       = aws_directory_service_directory.managed_ad.id
}

output "managed_ad_dns_ip_addresses" {
  description = "Managed Microsoft AD DNS IP 주소 목록."
  value       = aws_directory_service_directory.managed_ad.dns_ip_addresses
}

output "managed_ad_security_group_id" {
  description = "AWS Directory Service가 생성한 AD 보안 그룹 ID."
  value       = aws_directory_service_directory.managed_ad.security_group_id
}

output "fsx_file_system_id" {
  description = "FSx ONTAP 파일 시스템 ID."
  value       = aws_fsx_ontap_file_system.this.id
}

output "fsx_storage_virtual_machine_id" {
  description = "FSx ONTAP SVM ID."
  value       = aws_fsx_ontap_storage_virtual_machine.this.id
}

output "fsx_volume_id" {
  description = "공유 볼륨 ID."
  value       = aws_fsx_ontap_volume.shared.id
}

output "kms_key_arn" {
  description = "FSx 암호화용 KMS Key ARN."
  value       = aws_kms_key.fsx.arn
}

output "fsx_log_group_name" {
  description = "FSx 운영 로그용 CloudWatch Logs 그룹 이름."
  value       = aws_cloudwatch_log_group.fsx_ontap.name
}
