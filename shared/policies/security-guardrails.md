# Security Guardrails Policy

## 1. 목적  
본 문서는 클라우드 환경에서 인프라 설계 및 구현 시  
반드시 준수해야 하는 보안 기준을 정의한다.  

본 정책은 특정 CSP(AWS, Azure, GCP)에 종속되지 않으며  
공통 보안 원칙을 기반으로 한다.

---

## 2. 기본 원칙

- 최소 권한 원칙 (Least Privilege)
- 네트워크 접근 최소화 (Zero Trust 지향)
- 데이터 암호화 기본 적용 (Encryption by Default)
- 퍼블릭 노출 최소화 (Private by Default)
- 보안 자동화 및 정책 기반 관리 (Policy as Code)

---

## 3. 네트워크 보안

### 3.1 네트워크 격리
- 모든 리소스는 논리적 네트워크(VPC/VNet 등) 내부에 배치
- 인터넷 직접 노출 리소스 최소화
- 내부 서비스는 Private 네트워크만 사용

### 3.2 서브넷 / 세그멘테이션
- Public / Private 영역 명확히 분리
- DB, 내부 API, 인증 시스템은 반드시 Private 영역 배치
- 서비스 간 네트워크는 최소 경로만 허용

### 3.3 접근 제어 (Network Policy)
- IP 기반 접근 제어 최소화 (가능 시 Identity 기반 접근 사용)
- Any(0.0.0.0/0) 허용은 반드시 승인 절차 필요
- 필요한 포트만 명시적으로 허용 (deny by default)

### 3.4 외부 접근 통제
- Bastion 또는 Jump Host 사용 권장
- 관리 접근은 VPN / Private Endpoint 우선 적용
- Public IP 직접 SSH/RDP 접근 금지

---

## 4. IAM / Identity 보안

- Role 기반 접근 제어 (RBAC) 사용
- 사용자 직접 권한 부여 금지 (Group/Role 기반)
- 장기 인증 정보(Long-lived credentials) 사용 최소화
- 서비스 간 인증은 Managed Identity / Service Account 사용

### 4.1 정책 설계
- 최소 권한 원칙 준수
- Wildcard (*) 사용 금지 또는 제한
- 조건 기반 정책 적극 활용 (IP, Tag, Time 등)

### 4.2 인증 보안
- MFA 필수 적용 (관리자 및 중요 계정)
- SSO 기반 인증 권장 (IdP 연동)

---

## 5. 데이터 보안

### 5.1 저장 데이터 (Data at Rest)
- 모든 저장소 암호화 기본 적용
  - Block Storage
  - Object Storage
  - Database
- CSP 제공 키 또는 고객 관리 키(KMS/CMK) 사용

### 5.2 전송 데이터 (Data in Transit)
- TLS 1.2 이상 사용
- HTTP 사용 금지 (HTTPS 강제)

### 5.3 비밀 정보 관리
- Secret은 코드/설정 파일에 저장 금지
- Secret Manager / Key Vault / Secret Manager(GCP) 등 사용
- 주기적 Rotation 적용

---

## 6. Kubernetes 보안

### 6.1 접근 제어
- RBAC 최소 권한 적용
- Cluster Admin 권한 제한

### 6.2 Pod 보안
- root 사용자 실행 금지
- privileged container 금지
- readOnlyRootFilesystem 사용 권장

### 6.3 이미지 보안
- 신뢰된 레지스트리만 사용
- 이미지 스캔 필수 (취약점 검사)
- latest 태그 사용 금지

### 6.4 네트워크 보안
- NetworkPolicy 적용 (default deny)
- Pod 간 통신 최소화

### 6.5 Secret 관리
- Secret 평문 저장 금지
- Encryption at Rest 활성화
- 외부 Secret Manager 연동 권장

---

## 7. 로그 및 감사

- Audit 로그 활성화 (Cloud Audit / Activity Logs 등)
- 모든 API 호출 로그 수집
- 중앙 로그 시스템으로 집계

### 7.1 로그 보관
- 최소 보관 기간 정의 (예: 90일 이상)
- 무결성 보장 (삭제/변조 방지)

### 7.2 모니터링
- 이상 행위 탐지 (Anomaly Detection)
- 보안 이벤트 알림 자동화

---

## 8. 금지 사항

- 퍼블릭 Object Storage 공개 설정 금지
- 하드코딩된 credentials 사용 금지
- 모든 포트 개방 금지
- 루트/관리자 계정 일상 사용 금지
- 승인되지 않은 외부 이미지 사용 금지

---

## 9. IaC 적용 기준 (Terraform 등)

- 보안 설정은 반드시 명시적으로 정의 (implicit default 금지)
- 암호화 옵션 항상 활성화
- 네트워크 규칙 최소화
- 태그/라벨 기반 리소스 관리 필수
- 정책 위반 시 배포 차단 (Policy Enforcement)

---

## 10. 검증 기준

아래 조건을 만족해야 한다:

- 정적 분석 통과 (tfsec, checkov 등)
- 정책 위반 없음 (Policy as Code 기준)
- 퍼블릭 노출 리소스 없음 (예외 시 승인 필요)
- 취약점 스캔 통과 (이미지/패키지 포함)