# Spec — Plvyx NAS

> Claude 작성 → Codex 입력용
> 참조: `input/request.md`

---

## 1. 설계 요약

- **결정된 아키텍처:**
  AWS Seoul 리전(ap-northeast-2) 단일 VPC 내에 Amazon FSx for NetApp ONTAP(Single-AZ)와
  AWS Managed Microsoft AD(Multi-AZ)를 배포하고, IPSec Site-to-Site VPN을 통해 온프레미스와 연결하는 구성.

- **핵심 설계 결정 사항:**
  - FSx Single-AZ 선택: DR 없음, AD만 Multi-AZ 요건에 따른 비용 최적화
  - Managed Microsoft AD (Standard Edition): 10명 수준 사용자 규모에 적합, LDAP + Kerberos 인증 제공
  - 모든 리소스를 Private Subnet에만 배치 (퍼블릭 서브넷 없음)
  - VPN 트래픽 경로: 온프레미스 → Virtual Private Gateway → FSx / AD Private Subnet
  - FSx 스토리지: 5TB 총용량 (SSD Tier 1TB + Capacity Pool 4TB), 처리량 128 MBps

- **채택하지 않은 대안 및 사유:**
  - FSx Multi-AZ: DR 불필요 요건 및 비용 절감 이유로 제외
  - AWS Transfer Family (SFTP): Out of Scope 명시
  - Self-managed Windows File Server (EC2): 운영 부담 및 FSx 완전관리형 이점 대비 열위
  - Direct Connect: 구성 리드타임 및 비용 대비 S2S VPN으로 충분한 150Mbps 충족 가능

---

## 2. 컴포넌트 구성

| 컴포넌트 | 역할 | 기술 스택 | 비고 |
|----------|------|-----------|------|
| Amazon FSx for NetApp ONTAP | SMB/NFS 공유 파일 서버 | FSx ONTAP Single-AZ | 5TB, 128 MBps |
| AWS Managed Microsoft AD | LDAP/Kerberos 사용자 인증 및 권한 관리 | Directory Service (Standard Edition) | Multi-AZ, nas.plvyx.com |
| Amazon VPC | 네트워크 격리 | VPC + Private Subnets × 3 | 퍼블릭 서브넷 없음 |
| Virtual Private Gateway | IPSec S2S VPN 종단점 (AWS 측) | VGW | Route Propagation 활성화 |
| Customer Gateway | IPSec S2S VPN 종단점 (온프레미스 측) | CGW | 온프레미스 VPN 장비 Public IP 사전 확인 필요 |
| AWS Site-to-Site VPN | 온프레미스 ↔ AWS 암호화 터널 | IPSec VPN | 2 tunnels (고가용성 구성) |
| AWS KMS | FSx 저장 데이터 암호화 | Customer Managed Key | |
| Security Groups | 포트 기반 트래픽 제어 | SG (FSx / AD) | deny by default |
| Amazon CloudWatch | 로그 수집 및 메트릭 모니터링 | CloudWatch Logs + Metrics + Alarms | |

---

## 3. 아키텍처 다이어그램

```
[온프레미스 사용자]
      │
      │ SMB (TCP 445) / NFS (TCP/UDP 2049) over IPSec VPN
      ▼
[온프레미스 VPN 장비 (Customer Gateway)]
      │
      │ IPSec Tunnel (2 tunnels)
      ▼
[Virtual Private Gateway: plvyx-nas-prod-vpn-vgw]
      │
      ▼
┌─────────────────────────────────────────────────────────────┐
│ VPC: plvyx-nas-prod-vpc  (10.100.0.0/16)                    │
│ Region: ap-northeast-2                                       │
│                                                             │
│  ┌──────────────────────────────────┐                       │
│  │ Private Subnet A                 │  ap-northeast-2a      │
│  │ plvyx-nas-prod-vpc-subnet-       │  10.100.10.0/24       │
│  │ private-a                        │                       │
│  │                                  │                       │
│  │  ┌────────────────────────────┐  │                       │
│  │  │ FSx for NetApp ONTAP       │  │                       │
│  │  │ plvyx-nas-prod-fsx-ontap   │  │                       │
│  │  │ 5TB (1TB SSD + 4TB HDD)    │  │                       │
│  │  │ 128 MBps, Single-AZ        │  │                       │
│  │  └────────────────────────────┘  │                       │
│  └──────────────────────────────────┘                       │
│            │ TCP/UDP 88, 389, 636, 53, 445, 135, 49152-65535│
│            ▼                                                 │
│  ┌──────────────────────────────────┐                       │
│  │ Private Subnet B                 │  ap-northeast-2a      │
│  │ plvyx-nas-prod-vpc-subnet-       │  10.100.11.0/24       │
│  │ private-b                        │                       │
│  │  [Managed AD DC1]                │                       │
│  └──────────────────────────────────┘                       │
│  ┌──────────────────────────────────┐                       │
│  │ Private Subnet C                 │  ap-northeast-2c      │
│  │ plvyx-nas-prod-vpc-subnet-       │  10.100.12.0/24       │
│  │ private-c                        │                       │
│  │  [Managed AD DC2]                │                       │
│  └──────────────────────────────────┘                       │
│                                                             │
│ Domain: nas.plvyx.com                                       │
└─────────────────────────────────────────────────────────────┘
```

참조: `input/architecture/service-architecture.png`, `input/architecture/network-flow.png`

---

## 4. 연동 명세

| 출발 | 도착 | 프로토콜 / 포트 | 인증 방식 | 비고 |
|------|------|----------------|-----------|------|
| 온프레미스 사용자 | FSx ONTAP | TCP 445 (SMB) | Kerberos (AD 연동) | Windows / macOS |
| 온프레미스 사용자 | FSx ONTAP | TCP/UDP 2049 (NFS) | Kerberos (AD 연동) | Linux |
| FSx ONTAP | Managed AD | TCP/UDP 88 (Kerberos) | - | 인증 요청 |
| FSx ONTAP | Managed AD | TCP/UDP 389 (LDAP) | - | 디렉터리 조회 |
| FSx ONTAP | Managed AD | TCP 636 (LDAPS) | - | 암호화된 LDAP |
| FSx ONTAP | Managed AD | TCP/UDP 53 (DNS) | - | 도메인 이름 해석 |
| FSx ONTAP | Managed AD | TCP 445 (SMB) | - | AD 통신 |
| FSx ONTAP | Managed AD | TCP 135 (RPC Endpoint Mapper) | - | AD RPC |
| FSx ONTAP | Managed AD | TCP 49152–65535 (Dynamic RPC) | - | AD RPC 동적 포트 |

---

## 5. 데이터 / 스토리지 설계

- **데이터 저장소 및 용도:**
  - FSx ONTAP 볼륨: 임직원 공유 파일 저장소 (문서, 업무 데이터)
  - SVM(Storage Virtual Machine): FSx 기본 SVM 1개, SMB 및 NFS 모두 제공

- **스키마 / 데이터 모델 (간략):**
  - 파일 시스템 구조는 AD 그룹 기반 폴더 권한 정책으로 관리
  - 볼륨 Security Style: `MIXED` — NTFS 권한(SMB) + UNIX 권한(NFS) 동시 지원 (ONTAP 듀얼 프로토콜)

- **암호화 적용 범위:**
  - 저장 데이터(Data at Rest): AWS KMS Customer Managed Key(CMK) 기반 FSx 볼륨 암호화
  - 전송 데이터(Data in Transit): SMB Signing (Kerberos 기반), VPN IPSec 터널 암호화

- **보존 / 삭제 정책:**
  - FSx 자동 스냅샷: AWS 기본 제공 `default` 정책 사용 (커스텀 정책은 Terraform 미지원 — ONTAP CLI/REST 전용)
  - FSx 백업: 일 1회, 보관 30일
  - 스냅샷 및 백업 삭제는 수동 승인 후 수행

---

## 6. 보안 설계

- **IAM / 권한 구조:**
  - FSx 관리용 IAM Role: 최소 권한, FSx 및 KMS 작업만 허용
  - Terraform 실행용 IAM Role: Infra 프로비저닝 권한 범위만 부여, Wildcard(*) 사용 금지
  - 사용자 파일 접근 권한: Managed AD 그룹 기반 NTFS/UNIX ACL 관리

- **네트워크 경계 (public / private):**
  - 퍼블릭 서브넷 없음. 모든 리소스는 Private Subnet에 배치
  - 인터넷 게이트웨이(IGW) 없음
  - 온프레미스 접근: VPN 전용 (Public IP 직접 SSH/접근 금지)
  - Security Group `plvyx-nas-prod-sg-fsx`: 온프레미스 CIDR → TCP 445, TCP/UDP 2049만 허용
  - Security Group `plvyx-nas-prod-sg-ad`: FSx SG → AD 필수 포트만 허용

- **Secret 관리 방식:**
  - AD 관리자 패스워드: AWS Secrets Manager에 저장, Terraform에 하드코딩 금지
  - KMS CMK: Terraform 상태 파일에 ARN만 기록, 키 자료 코드 외부 저장 금지

- **기본 정책 예외 항목:**
  - MFA 없음 (요청 명시): AD 인증은 LDAP + Kerberos만 적용 (사용자 측 MFA 구성 별도)

---

## 7. 인프라 명세 (For Codex)

### 7.1 리소스 목록

| 리소스 | 이름 (`naming.md` 패턴 적용) | 스펙 / 설정 | 비고 |
|--------|------------------------------|-------------|------|
| aws_vpc | `plvyx-nas-prod-vpc` | CIDR: 10.100.0.0/16, DNS hostnames/support: enabled | |
| aws_subnet (FSx) | `plvyx-nas-prod-vpc-subnet-private-a` | 10.100.10.0/24, AZ: ap-northeast-2a | FSx 배치용 |
| aws_subnet (AD-a) | `plvyx-nas-prod-vpc-subnet-private-b` | 10.100.11.0/24, AZ: ap-northeast-2a | AD DC1 |
| aws_subnet (AD-c) | `plvyx-nas-prod-vpc-subnet-private-c` | 10.100.12.0/24, AZ: ap-northeast-2c | AD DC2 |
| aws_route_table | `plvyx-nas-prod-vpc-rt` | VGW Route Propagation 활성화 | 3개 서브넷 연결 |
| aws_vpn_gateway | `plvyx-nas-prod-vpn-vgw` | VPC 연결 | Route Propagation 활성화 |
| aws_customer_gateway | `plvyx-nas-prod-vpn-cgw` | 온프레미스 VPN IP, BGP ASN 65000 (Static 사용 시 생략) | IP 사전 확인 필요 |
| aws_vpn_connection | `plvyx-nas-prod-vpn-s2s` | Static routing, 2 tunnels | 온프레미스 CIDR 사전 확인 필요 |
| aws_directory_service_directory | `plvyx-nas-prod-managed-ad` | Standard Edition, nas.plvyx.com, subnet-b + subnet-c | AD 관리자 PW → Secrets Manager |
| aws_fsx_ontap_file_system | `plvyx-nas-prod-fsx-ontap` | Single-AZ, 1024 GiB SSD, 128 MBps throughput, KMS CMK 암호화 | Capacity Pool: 4096 GiB |
| aws_fsx_ontap_storage_virtual_machine | `plvyx-nas-prod-fsx-svm` | 기본 SVM, Active Directory 조인 (nas.plvyx.com) | |
| aws_fsx_ontap_volume | `plvyx-nas-prod-fsx-vol` | 볼륨 크기 정의 필요 (초기 1TB 권장) | Tiering policy: auto |
| aws_security_group (FSx) | `plvyx-nas-prod-sg-fsx` | 인바운드: TCP 445, TCP/UDP 2049 (온프레미스 CIDR) | 아웃바운드: AD SG만 허용 |
| aws_security_group_rule (AD) | `plvyx-nas-prod-sg-ad` | FSx SG → AD SG 인바운드 규칙 추가 (88, 389, 636, 53, 445, 135, 49152-65535) | Managed AD는 디렉터리 생성 시 AWS가 SG 자동 생성 — 독립 리소스 생성 불가 |
| aws_kms_key | `plvyx-nas-prod-kms-fsx` | CMK, 키 로테이션 활성화 | FSx 암호화 전용 |
| aws_cloudwatch_metric_alarm | `plvyx-nas-prod-fsx-capacity-alarm` | FSx 용량 80% 임계치 알람 | SNS 연동 권장 |
| aws_cloudwatch_metric_alarm | `plvyx-nas-prod-fsx-throughput-alarm` | Throughput 사용률 80% 임계치 알람 | SNS 연동 권장 |
| aws_cloudwatch_metric_alarm | `plvyx-nas-prod-vpn-tunnel-alarm` | VPN 터널 DOWN 알람 | SNS 연동 권장 |

### 7.2 환경별 차이

| 항목 | dev | stage | prod |
|------|-----|-------|------|
| FSx 스토리지 용량 | - | - | SSD 1TB + Capacity Pool 4TB |
| FSx 처리량 | - | - | 128 MBps |
| Managed AD Edition | - | - | Standard |
| VPN 구성 | - | - | S2S VPN (IPSec) |
| 암호화 | - | - | KMS CMK |
| 백업 보관 | - | - | 30일 |

> dev / stage 환경 배포 계획 없음 (prod 단일 환경)

### 7.3 디렉터리 구조 (권장)

```
projects/plvyx-nas/
├── input/
│   ├── request.md
│   └── architecture/
│       ├── service-architecture.png
│       └── network-flow.png
├── spec/
│   ├── spec.md
│   ├── module-contract.json
│   ├── constraints.yaml
│   └── acceptance-criteria.md
├── output/
│   ├── terraform/
│   │   ├── modules/
│   │   │   ├── network/        # VPC, Subnet, VGW, CGW, VPN
│   │   │   ├── directory/      # Managed Microsoft AD
│   │   │   ├── security/       # Security Group (FSx), SG Rule (AD)
│   │   │   ├── storage/        # KMS, FSx ONTAP, SVM, Volume
│   │   │   └── observability/  # CloudWatch Log Group, Alarms
│   │   └── envs/
│   │       └── prod/           # provider, versions, variables, locals, main, outputs
│   ├── scripts/
│   │   └── create-smb-share.ps1
│   ├── Makefile
│   ├── implementation-notes.md
│   └── validation-plan.md
└── qa/
```

> 모듈명은 설계 컴포넌트 기반 제안이며, 실제 분할은 Codex 재량이다.

### 7.4 구현 시 주의사항

- `aws_customer_gateway`의 `ip_address`는 온프레미스 VPN 장비의 Public IP로 설정 (변수로 외부 입력)
- `aws_vpn_connection`의 `static_routes_destinations`는 온프레미스 CIDR 목록으로 설정 (변수 처리)
- Managed AD 관리자 패스워드는 `aws_secretsmanager_secret`으로 생성 후 FSx SVM 조인 시 참조
- FSx ONTAP 프로비저닝 시간이 길기 때문에 `terraform apply` 타임아웃 설정 권장 (30분 이상)
- `aws_fsx_ontap_file_system`의 `subnet_ids`는 Single-AZ이므로 `[subnet-a]` 1개만 지정
- Capacity Pool tiering policy는 `auto`로 설정하여 비용 최적화
- terraform-aws-modules 활용 가능 모듈: `terraform-aws-modules/vpc/aws`, `terraform-aws-modules/vpn-gateway/aws`
- 모듈이 없는 리소스(FSx ONTAP, Managed AD)는 AWS Provider 공식 리소스 직접 사용
- `common_tags` locals 블록으로 모든 리소스에 일관된 태그 적용

---

## 8. 운영 / 관측성 설계

- **로그 수집 경로 및 포맷:**
  - FSx Administration 로그 → CloudWatch Logs (`/aws/fsx/ontap`)
  - VPN 터널 상태 → CloudWatch Metrics (자동 수집)
  - AD 이벤트 로그 → CloudWatch Logs (Directory Service 기본 제공)

- **핵심 메트릭 및 임계값:**
  - FSx `StorageCapacityUtilization`: 임계값 80% (경보)
  - FSx `DataReadBytes` + `DataWriteBytes`: 합산 처리량 임계값 100 MBps (경보, 수식으로 계산)
  - VPN `TunnelState`: 0 (DOWN) 시 경보

- **알림 조건:**
  - FSx 스토리지 사용률 80% 초과 → CloudWatch Alarm → SNS (수동 확장 검토)
  - VPN 터널 DOWN → CloudWatch Alarm → SNS (즉시 확인 필요)
  - FSx 처리량 80% 초과 → CloudWatch Alarm → SNS (성능 검토)

- **장애 대응 절차 요약:**
  1. FSx 상태 이상: CloudWatch 알람 확인 → FSx 콘솔 이벤트 로그 확인 → 필요 시 AWS Support 케이스 등록
  2. AD 장애 시: Managed AD는 Multi-AZ이므로 DC 자동 페일오버 → 인증 불가 지속 시 AWS Support 요청
  3. VPN 터널 DOWN: AWS 콘솔 VPN 터널 상태 확인 → 온프레미스 VPN 장비 측 확인 → IKE 재협상 시도

---

## 9. 미결 사항 / 가정

| 항목 | 현재 가정 | 확인 필요 여부 |
|------|-----------|---------------|
| 온프레미스 VPN 장비 Public IP | 미확인 — Terraform 변수로 입력받도록 설계 | [V] 필요 |
| 온프레미스 내부 CIDR | 미확인 — Terraform 변수로 입력받도록 설계 | [V] 필요 |
| Managed AD 관리자 패스워드 | Secrets Manager 자동 생성, 초기 값은 수동 설정 가정 | [V] 필요 |
| 도메인 네임 (nas.plvyx.com) | request.md에 명시됨 — 확정으로 간주 | [ ] 불필요 |
| FSx 초기 볼륨 크기 | 1TB 권장 (나머지 Capacity Pool tiering) | [V] 필요 |
| CloudWatch Alarm SNS 토픽 | 기존 SNS 없음 가정 — 신규 생성 또는 기존 ARN 변수 입력 | [V] 필요 |
| IaC 실행 IAM Role | Terraform 실행 주체 IAM Role 별도 구성 필요 | [V] 필요 |
| 월 예산 $800 충족 여부 | FSx($100~150) + Managed AD($100) + VPN($50) + KMS(소액) 기준 $300~320 예상 → 충족 가정 | [ ] 불필요 |

---

## 10. Gemini 검증 요청

> 이 섹션은 Gemini에게 넘길 때 `qa/review.md`와 함께 전달한다.

- **반드시 검증해야 할 항목:**
  - Security Group 인바운드/아웃바운드 규칙이 FSx ↔ AD 연동 포트 명세와 일치하는지 확인
  - 퍼블릭 서브넷, IGW, 퍼블릭 IP 리소스가 없는지 확인
  - KMS CMK 암호화가 FSx에 명시적으로 적용되는지 확인
  - Managed AD 패스워드가 코드 내 하드코딩 없이 Secrets Manager 참조로 처리되는지 확인
  - VPN Static Route가 온프레미스 CIDR 변수로 처리되는지 확인

- **정책 준수 확인 포인트:**
  - `security-guardrails.md` §3 (네트워크 보안): Private Only 구성, deny by default SG
  - `security-guardrails.md` §5 (데이터 보안): KMS 암호화, TLS/SMB Signing, Secret Manager 사용
  - `naming.md`: 모든 리소스 이름이 `<project>-<env>-<service>-<component>[-<detail>]` 패턴 준수
  - `tagging.md`: `name`, `env`, `creator`, `version` 태그 전체 리소스 적용

- **PASS 기준:**
  - tfsec / checkov 정적 분석 통과 (High/Critical 0건)
  - 퍼블릭 노출 리소스 0건
  - 태그 누락 리소스 0건
  - FSx ↔ AD 연동 포트 전체 허용 확인
  - Secrets Manager 참조 확인 (하드코딩 없음)
