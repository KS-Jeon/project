# Plvyx NAS

Plvyx NAS 프로젝트는 AWS Seoul(`ap-northeast-2`)에 Amazon FSx for NetApp ONTAP, AWS Managed Microsoft AD, Site-to-Site VPN을 조합해 온프레미스 사용자가 SMB/NFS로 접근하는 공유 파일 서버를 구성한다. 구현은 `spec/*`를 기준으로 하며, 퍼블릭 서브넷·IGW·NAT 없이 private-only 네트워크를 유지하고, FSx 저장 데이터는 고객 관리형 KMS 키로 암호화한다.

## 구현 명세

### 사용 서비스

- Amazon VPC: `10.100.0.0/16` 네트워크 격리
- AWS Site-to-Site VPN: 온프레미스와 AWS 간 IPSec 연결
- AWS Managed Microsoft AD: `nas.plvyx.com` 도메인 기반 인증
- Amazon FSx for NetApp ONTAP: SMB/NFS 공유 파일 서버
- AWS KMS: FSx 저장 데이터 암호화
- Amazon CloudWatch: 용량, 처리량, VPN 터널 상태 모니터링

### 선택 이유

- FSx ONTAP은 SMB/NFS 듀얼 프로토콜과 AD 연동을 지원해 이기종 OS 공유 파일 서버 요구에 맞다.
- Managed Microsoft AD는 자체 AD 운영 부담을 줄이면서 Kerberos/LDAP 인증을 제공한다.
- Direct Connect 대신 S2S VPN을 사용해 초기 구축 비용과 리드타임을 줄인다.
- DR이 요구되지 않아 FSx는 Single-AZ, AD만 Multi-AZ로 분리해 비용을 최적화했다.

### 구현 방식

- Terraform으로 VPC, VGW, Customer Gateway, VPN Connection, Managed AD, FSx, KMS, CloudWatch를 생성한다.
- VPC는 `terraform-aws-modules/vpc/aws`, VPN은 `terraform-aws-modules/vpn-gateway/aws`를 사용한다.
- FSx ONTAP과 Managed AD는 AWS provider 리소스를 직접 사용한다.
- 모든 태그는 `env=prod`, `creator=ksjeon`, `version=20260407`을 기준으로 적용한다.

### 아키텍처 역할

- Private subnet A: FSx ONTAP
- Private subnet B/C: Managed AD 도메인 컨트롤러
- VGW/CGW/VPN: 온프레미스 트래픽을 private route table로 전달
- Security Groups: 온프레미스 SMB/NFS, FSx -> AD 필수 포트만 허용
- CloudWatch Alarm: FSx 용량 80%, 처리량 100 MBps, VPN 터널 DOWN 감시

### 운영 고려사항

- `ad_admin_password_secret_arn` secret은 Secrets Manager에 미리 준비되어 있어야 한다.
- AWS Managed AD의 보안 그룹은 AWS가 생성하므로 Terraform은 규칙과 태그만 추가 관리한다.
- `/shared` junction path는 Terraform으로 생성되지만, 실제 SMB share 객체는 ONTAP 관리 명령이 필요해 `output/scripts/create-smb-share.ps1`를 함께 제공한다.
- `create-smb-share.ps1`를 실제 실행하려면 FSx 관리 엔드포인트에 접속 가능한 ONTAP 관리자 계정이 별도로 준비되어 있어야 한다.
- 스냅샷 정책은 Terraform에서 제공되는 FSx ONTAP 기본 정책 `default`를 사용한다. 스펙의 일 1회/7일 보관을 정확히 맞추려면 ONTAP CLI 또는 REST API로 custom policy를 추가 구성해야 한다.
- `/aws/fsx/ontap` 로그 그룹은 미리 만들지만, ONTAP EMS 이벤트 전달 자체는 별도 운영 설정이 필요하다.

## 배포 절차

```bash
terraform -chdir=projects/plvyx-nas/output/terraform init
terraform -chdir=projects/plvyx-nas/output/terraform plan \
  -var="onprem_public_ip=<public-ip>" \
  -var="onprem_cidr=<cidr>" \
  -var="ad_admin_password_secret_arn=<secret-arn>"
terraform -chdir=projects/plvyx-nas/output/terraform apply
```

`cloudwatch_sns_topic_arn`은 선택 값이다. 배포 후 SMB share 생성이 필요하면 `projects/plvyx-nas/output/scripts/create-smb-share.ps1`를 사용한다.

## 주요 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `aws_region` | AWS 리전 | `ap-northeast-2` |
| `onprem_public_ip` | 온프레미스 VPN 장비 공인 IP | 필수 |
| `onprem_cidr` | 온프레미스 내부 CIDR | 필수 |
| `ad_admin_password_secret_arn` | AD 암호/조인 계정 정보가 저장된 Secrets Manager ARN | 필수 |
| `cloudwatch_sns_topic_arn` | CloudWatch 알림 SNS Topic | 없음 |
| `fsx_storage_capacity_gib` | FSx SSD 용량 | `1024` |
| `fsx_throughput_capacity_mbps` | FSx 처리량 | `128` |
| `fsx_volume_size_megabytes` | 공유 볼륨 논리 크기 | `5242880` |
| `ad_organizational_unit_distinguished_name` | SVM 객체를 생성할 OU DN | `OU=Computers,OU=nas,DC=nas,DC=plvyx,DC=com` |

Secrets Manager secret은 아래 키를 포함한 JSON 형태를 권장한다.

- `CUSTOMER_MANAGED_ACTIVE_DIRECTORY_USERNAME`
- `CUSTOMER_MANAGED_ACTIVE_DIRECTORY_PASSWORD`

## 출력 값

- `vpc_id`
- `private_subnet_ids`
- `private_route_table_ids`
- `customer_gateway_id`
- `vpn_connection_id`
- `vpn_tunnel_addresses`
- `managed_ad_id`
- `managed_ad_dns_ip_addresses`
- `managed_ad_security_group_id`
- `fsx_file_system_id`
- `fsx_storage_virtual_machine_id`
- `fsx_volume_id`
- `kms_key_arn`
- `fsx_log_group_name`

## 디렉터리 구조

```text
projects/plvyx-nas/
├── input/
├── spec/
├── output/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── versions.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   ├── vpc.tf
│   │   ├── vpn.tf
│   │   ├── security_groups.tf
│   │   ├── managed_ad.tf
│   │   ├── fsx.tf
│   │   ├── kms.tf
│   │   └── cloudwatch.tf
│   ├── scripts/
│   │   └── create-smb-share.ps1
│   ├── k8s/
│   ├── helm/
│   ├── Makefile
│   ├── implementation-notes.md
│   └── validation-plan.md
└── README.md
```
