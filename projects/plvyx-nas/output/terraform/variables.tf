variable "aws_region" {
  description = "AWS 리전. 스펙상 ap-northeast-2(서울)로 고정한다."
  type        = string
  default     = "ap-northeast-2"
}

variable "creator" {
  description = "tagging.md 기준 creator 태그 값."
  type        = string
  default     = "ksjeon"
}

variable "version_tag" {
  description = "tagging.md 기준 version 태그 값. acceptance-criteria의 20260407을 그대로 사용한다."
  type        = string
  default     = "20260407"
}

variable "directory_domain_name" {
  description = "Managed Microsoft AD 도메인 이름."
  type        = string
  default     = "nas.plvyx.com"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.100.0.0/16"
}

variable "onprem_public_ip" {
  description = "온프레미스 VPN 장비의 공인 IP 주소."
  type        = string
}

variable "onprem_cidr" {
  description = "온프레미스 내부 CIDR. Security Group 및 VPN static route에 사용한다."
  type        = string
}

variable "customer_gateway_bgp_asn" {
  description = "Customer Gateway BGP ASN. static routing 구성이라도 명시적으로 유지한다."
  type        = number
  default     = 65000
}

variable "ad_admin_password_secret_arn" {
  description = "Managed AD 관리자 암호 및 FSx 도메인 조인 계정 정보가 저장된 Secrets Manager ARN."
  type        = string
}

variable "cloudwatch_sns_topic_arn" {
  description = "CloudWatch Alarm 알림용 SNS Topic ARN. 비우면 알람만 생성하고 액션은 연결하지 않는다."
  type        = string
  default     = null
  nullable    = true
}

variable "fsx_storage_capacity_gib" {
  description = "FSx ONTAP SSD 스토리지 용량(GiB)."
  type        = number
  default     = 1024
}

variable "fsx_throughput_capacity_mbps" {
  description = "FSx ONTAP 처리량 용량(MBps)."
  type        = number
  default     = 128
}

variable "fsx_volume_size_megabytes" {
  description = "공유 볼륨 논리 크기(MiB). 5TiB로 설정해 요청된 총 5TB 용량을 반영한다."
  type        = number
  default     = 5242880
}

variable "fsx_backup_retention_days" {
  description = "FSx 자동 백업 보관 일수."
  type        = number
  default     = 30
}

variable "fsx_daily_backup_start_time" {
  description = "FSx 일일 자동 백업 시작 시각(UTC, HH:MM)."
  type        = string
  default     = "02:00"
}

variable "fsx_weekly_maintenance_start_time" {
  description = "FSx 주간 유지보수 시작 시각(UTC, d:HH:MM)."
  type        = string
  default     = "7:03:00"
}

variable "ad_netbios_name" {
  description = "FSx SVM이 Active Directory에 생성할 NetBIOS 이름."
  type        = string
  default     = "NAS"
}

variable "ad_delegated_administrators_group" {
  description = "AWS Managed Microsoft AD 사용 시 FSx 관리 권한을 위임할 AD 그룹명."
  type        = string
  default     = "AWS Delegated FSx Administrators"
}

variable "ad_organizational_unit_distinguished_name" {
  description = "FSx SVM 컴퓨터 객체를 배치할 OU DN."
  type        = string
  default     = "OU=Computers,OU=nas,DC=nas,DC=plvyx,DC=com"
}

variable "log_retention_days" {
  description = "CloudWatch Logs 보관 일수."
  type        = number
  default     = 90
}

variable "fsx_capacity_alarm_threshold_percent" {
  description = "FSx SSD 용량 알람 임계치(퍼센트)."
  type        = number
  default     = 80
}

variable "fsx_throughput_alarm_threshold_mbps" {
  description = "FSx 처리량 알람 임계치(MBps). 스펙상 100 MBps로 유지한다."
  type        = number
  default     = 100
}

variable "vpn_tunnel_alarm_period_seconds" {
  description = "VPN 터널 상태 알람 수집 주기(초)."
  type        = number
  default     = 60
}
