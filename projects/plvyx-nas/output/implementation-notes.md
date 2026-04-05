# Implementation Notes — Plvyx NAS

## 1. 스펙 반영 요약

- `spec/spec.md` 기준으로 `prod` 단일 환경만 구현했다.
- VPC, VGW, CGW, Site-to-Site VPN, Managed Microsoft AD, FSx for ONTAP, KMS, CloudWatch Alarm을 Terraform으로 구성했다.
- `shared/policies/naming.md`, `tagging.md`, `security-guardrails.md`를 반영해 private-only 네트워크와 명시적 SG 규칙, 공통 태그를 적용했다.

## 2. 스펙과 AWS 서비스 제약이 만나는 지점

### Managed AD 리소스 이름

- `aws_directory_service_directory`는 실제 `name` 필드에 도메인 FQDN이 필요하므로 `nas.plvyx.com`을 사용했다.
- 스펙의 패턴형 이름 `plvyx-nas-prod-managed-ad`는 `description`, `Name`, `name` 태그에 반영했다.

### Managed AD 보안 그룹

- AWS Managed Microsoft AD는 디렉터리 생성 시 보안 그룹을 AWS가 자동 생성한다.
- 따라서 커스텀 `aws_security_group`를 디렉터리에 직접 부착하는 대신, AWS가 만든 보안 그룹 ID에 대해:
  - `aws_security_group_rule`로 FSx -> AD 인바운드 규칙을 추가하고
  - `aws_ec2_tag`로 `Name`/`name`/공통 태그를 부여했다.

### CloudWatch Logs 그룹

- 스펙의 로그 그룹 이름은 `/aws/fsx/ontap`로 생성했다.
- 이 이름은 AWS 예약 패턴이므로 `naming.md` 패턴 대신 로그 그룹 태그에 `plvyx-nas-prod-fsx-log`를 기록했다.
- ONTAP EMS/관리 이벤트를 실제로 이 로그 그룹으로 전달하는 설정은 AWS provider 리소스로 직접 노출되지 않아 별도 운영 구성 대상이다.

### SMB 공유 생성

- Terraform으로 볼륨과 `/shared` junction path까지 생성한다.
- 실제 SMB share 객체 생성은 ONTAP 관리 명령이 필요하므로 `output/scripts/create-smb-share.ps1` 보조 스크립트를 함께 제공했다.
- 스크립트를 사용하려면 FSx 관리 엔드포인트에 SSH 가능한 ONTAP 관리자 계정이 준비되어 있어야 한다.

### 스냅샷 정책

- FSx ONTAP 기본 제공 snapshot policy 중 일 단위와 가장 가까운 값은 `default`다.
- 스펙의 "일 1회 / 7일 보관"을 정확히 맞추려면 ONTAP CLI/REST로 custom snapshot policy를 별도 생성해야 하므로, Terraform 구현은 AWS 기본 제공 정책 `default`를 사용했다.

## 3. 비밀 정보 처리

- `ad_admin_password_secret_arn`은 AWS Secrets Manager의 기존 secret ARN을 받는다.
- secret 값은 아래 공식 키를 포함하는 JSON 형태를 권장한다.
  - `CUSTOMER_MANAGED_ACTIVE_DIRECTORY_USERNAME`
  - `CUSTOMER_MANAGED_ACTIVE_DIRECTORY_PASSWORD`
- 같은 secret의 password를 Managed AD 생성과 FSx SVM 도메인 조인에 재사용한다.

## 4. 구현 가정

- acceptance criteria가 요구하는 태그 버전은 현재 실행 환경 날짜와 무관하게 `20260407`로 고정했다.
- FSx SSD 용량은 1TiB로 유지하면서, 요청된 총 5TB 용량을 반영하기 위해 공유 볼륨 논리 크기는 5TiB(`5242880` MiB)로 설정했다.
- AWS Managed Microsoft AD 사용 시 요구되는 OU와 위임 그룹은 아래 기본값으로 두었다.
  - OU: `OU=Computers,OU=nas,DC=nas,DC=plvyx,DC=com`
  - Delegated group: `AWS Delegated FSx Administrators`

## 5. 후속 확인 포인트

- 온프레미스 `onprem_public_ip`, `onprem_cidr` 실제 값 입력
- Secrets Manager secret 내용 형식 확인
- VPN 터널 수립 후 static route propagation 동작 확인
- SVM 생성 후 SMB share 생성 스크립트 실행 여부 확인
