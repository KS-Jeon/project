output "kms_key_arn" {
  description = "KMS key ARN."
  value       = aws_kms_key.fsx.arn
}

output "fsx_file_system_id" {
  description = "FSx file system ID."
  value       = aws_fsx_ontap_file_system.this.id
}

output "fsx_storage_virtual_machine_id" {
  description = "FSx storage virtual machine ID."
  value       = aws_fsx_ontap_storage_virtual_machine.this.id
}

output "fsx_volume_id" {
  description = "FSx volume ID."
  value       = aws_fsx_ontap_volume.shared.id
}
