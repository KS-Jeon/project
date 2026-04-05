# Acceptance Criteria — Plvyx NAS

> 참조: `spec/spec.md`, `input/request.md`

---

## 1. 인프라 구성 검증

- [ ] VPC `plvyx-nas-prod-vpc` (10.100.0.0/16)가 ap-northeast-2에 배포됨
- [ ] 퍼블릭 서브넷, IGW, NAT Gateway가 생성되지 않음
- [ ] Private Subnet 3개가 각각 지정된 AZ와 CIDR로 배포됨
- [ ] Route Table에 VGW Route Propagation이 활성화됨
- [ ] Virtual Private Gateway가 VPC에 연결됨
- [ ] Site-to-Site VPN 연결 상태가 AVAILABLE이고 터널 2개가 UP

---

## 2. FSx ONTAP 검증

- [ ] `plvyx-nas-prod-fsx-ontap` Single-AZ로 배포됨 (ap-northeast-2a)
- [ ] 스토리지 용량: SSD 1,024 GiB, Throughput 128 MBps
- [ ] KMS CMK 암호화 활성화 확인 (`aws fsx describe-file-systems` → KmsKeyId 확인)
- [ ] 자동 백업 활성화 (보관 30일)
- [ ] SVM `plvyx-nas-prod-fsx-svm`이 Managed AD(nas.plvyx.com)에 조인됨
- [ ] SMB 공유 볼륨 `/shared` 마운트 경로 생성 확인
- [ ] Capacity Pool Tiering Policy: AUTO 설정 확인

---

## 3. Managed AD 검증

- [ ] `plvyx-nas-prod-managed-ad` Standard Edition, nas.plvyx.com 도메인 배포됨
- [ ] Multi-AZ 구성: subnet-b (ap-northeast-2a), subnet-c (ap-northeast-2c) 사용
- [ ] AD 관리자 패스워드가 Secrets Manager에서 참조 (코드 내 하드코딩 없음)
- [ ] FSx SVM이 AD 도메인에 성공적으로 조인됨 (FSx 콘솔 상태 확인)

---

## 4. 보안 검증

- [ ] `plvyx-nas-prod-sg-fsx` 인바운드: 온프레미스 CIDR → TCP 445, TCP/UDP 2049만 허용
- [ ] `plvyx-nas-prod-sg-fsx` 아웃바운드: AD SG로의 필수 포트만 허용
- [ ] `plvyx-nas-prod-sg-ad` 인바운드: FSx SG → 88, 389, 636, 53, 445, 135, 49152-65535만 허용
- [ ] KMS CMK 키 로테이션 활성화 확인
- [ ] tfsec 정적 분석 High/Critical 0건
- [ ] checkov 정책 위반 0건
- [ ] 퍼블릭 노출 리소스 0건 (tfsec PUBLIC_IP 관련 룰 통과)

---

## 5. 네이밍 / 태깅 검증

- [ ] 모든 리소스 이름이 `<project>-<env>-<service>-<component>[-<detail>]` 패턴 준수
- [ ] 모든 리소스에 `name`, `env`, `creator`, `version` 태그 적용
  - env: prod
  - creator: ksjeon
  - version: 20260407

---

## 6. 운영 / 관측성 검증

- [ ] CloudWatch Alarm `plvyx-nas-prod-fsx-capacity-alarm`: 80% 임계치 설정 확인
- [ ] CloudWatch Alarm `plvyx-nas-prod-fsx-throughput-alarm`: 임계치 설정 확인
- [ ] VPN 터널 DOWN 알람 설정 확인
- [ ] FSx 로그 `/aws/fsx/ontap` CloudWatch Logs 그룹 생성 확인

---

## 7. IaC 품질 검증

- [ ] `terraform fmt -check` 통과
- [ ] `terraform validate` 통과
- [ ] 모든 변수에 description 기재
- [ ] 온프레미스 IP / CIDR이 하드코딩 없이 변수로 처리됨
- [ ] README.md에 배포 절차, 변수 설명, 출력 값 기재
