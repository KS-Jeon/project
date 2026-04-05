# Validation Plan — Plvyx NAS

## 1. 사전 준비

- Terraform 1.5 이상 설치
- AWS 자격 증명 구성
- `onprem_public_ip`, `onprem_cidr`, `ad_admin_password_secret_arn` 값 준비
- 선택 사항: `cloudwatch_sns_topic_arn`

## 2. 정적 검증

```bash
make -C projects/plvyx-nas/output fmt-check
make -C projects/plvyx-nas/output validate
make -C projects/plvyx-nas/output tfsec
make -C projects/plvyx-nas/output checkov
```

기대 결과:

- `terraform fmt -check` 통과
- `terraform validate` 통과
- `tfsec`, `checkov` High/Critical 또는 정책 위반 0건

## 3. 배포 검증

```bash
terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod init
terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod plan
terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod apply
```

기대 결과:

- VPC 1개, Private Subnet 3개, IGW/NAT 0개
- VGW/CGW/VPN 연결 생성
- Managed AD와 FSx ONTAP 생성
- KMS CMK, CloudWatch Alarm, CloudWatch Logs 그룹 생성

## 4. AWS CLI 확인

### FSx

```bash
aws fsx describe-file-systems --file-system-ids "$(terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod output -raw fsx_file_system_id)"
aws fsx describe-storage-virtual-machines --filters Name=file-system-id,Values="$(terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod output -raw fsx_file_system_id)"
aws fsx describe-volumes --filters Name=file-system-id,Values="$(terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod output -raw fsx_file_system_id)"
```

확인 항목:

- deployment type: `SINGLE_AZ_1`
- `StorageCapacity` = `1024`
- `ThroughputCapacity` = `128`
- `KmsKeyId` 존재
- volume `JunctionPath` = `/shared`
- tiering policy = `AUTO`

### Managed AD

```bash
aws ds describe-directories --directory-ids "$(terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod output -raw managed_ad_id)"
```

확인 항목:

- type: `MicrosoftAD`
- edition: `Standard`
- DNS IP 2개 반환

### VPN

```bash
aws ec2 describe-vpn-connections --vpn-connection-ids "$(terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod output -raw vpn_connection_id)"
```

확인 항목:

- `State` = `available`
- 터널 2개 생성
- static routes가 `onprem_cidr`로 등록됨

## 5. CloudWatch 확인

확인 대상:

- Alarm `plvyx-nas-prod-fsx-capacity-alarm`
- Alarm `plvyx-nas-prod-fsx-throughput-alarm`
- Alarm `plvyx-nas-prod-vpn-tunnel-alarm`
- Log group `/aws/fsx/ontap`

## 6. 수동 후처리

SMB share 객체는 ONTAP 관리 명령으로 생성해야 한다.

```powershell
powershell -File projects/plvyx-nas/output/scripts/create-smb-share.ps1 `
  -ManagementEndpoint <svm-management-endpoint> `
  -SvmName plvyx-nas-prod-fsx-svm `
  -DryRun
```

검토 후 `-DryRun` 없이 실행한다.
