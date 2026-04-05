# Request — [Plvyx NAS]

---

## 1. 메타데이터

- **프로젝트 ID:** plvyx-nas
- **환경:** [ ] dev  [ ] stage  [ V ] prod
- **요청자:** ksjeon
- **작성일:** 20260407
- **우선순위:** [ ] 낮음  [ V ] 보통  [ ] 높음  [ ] 긴급
- **관련 티켓:** 없음

---

## 2. 요청 요약

- **한 줄 요약:**  
  Windows, macOS, Linux 등 모든 OS에서 사용자들이 작업할 수 있는 공유 파일 서버 구축 요청.

- **해결하려는 문제:**  
  현재의 데이터 공유 방식은 너무 느리기에 쾌적한 업무 환경을 위한 공유 스토리지 필요.

- **기대 결과:**  
  - 이기종 OS 지원  
  - 동시사용자 10명 정도가 원활하게 작업 가능한 환경

---

### In Scope

- SMB/NFS 기반 파일 서버 구축 (FSx ONTAP)
- AWS Managed Microsoft AD 연동을 통한 사용자 인증 및 권한 관리
- VPN 기반 온프레미스 ↔ AWS 연결 구성
- 동시 사용자 10명 기준 파일 읽기/쓰기 작업 시 평균 처리량 약 150Mbps 수준을 목표로 설계
- 파일 읽기/쓰기/수정/삭제 가능 (권한 기반 제어 포함)
- 기본 백업 정책 구성 (FSx 스냅샷 또는 FSx 백업)
- 견적 상 스토리지 용량 5TB, SSD 비율 20% 설정

---

### Out of Scope

- AWS Transfer Family(SFTP) 기반 파일 전송 환경 구축
- 클라이언트 OS 설정 및 드라이브 마운트 자동화
- 멀티 리전 DR(재해복구) 구성
- 애플리케이션 레벨 데이터 관리 (버전관리, 동기화 등)

---

### 에이전트별 산출물

| 에이전트 | 기대 산출물 |
|----------|------------|
| Claude   | 설계 결정, 아키텍처 선택 근거, spec 문서 |
| Codex    | IaC, 구현 코드, README, 검증 스크립트 |
| Gemini   | QA 보고서, 검증 결과 |
| 사람     | 최종 승인 및 예외 판단 |

---

## 3. 서비스 배경

- **서비스 설명:** FSx NetApp ONTAP 파일 서버 기반 공유 파일 서버
- **주요 사용자:** 임직원 60명 중 10명
- **도입 배경:** 현행 파일 공유 방식 성능 문제
- **기존 시스템:** 없음
- **운영 맥락:** IPSec VPN 기반 S2S 연결 예정

---

## 4. 기능 요구사항

### 4.1 서비스 구성

- **아키텍처 유형:** IPSec VPN 기반 SMB/NFS 파일 서버

- **구성 요소 및 역할:**
  - Amazon FSx for NetApp ONTAP: 공유 파일 서버
  - Amazon VPC: Private Subnet 3개 (FSx 1, AD 2)
  - 온프레미스 VPN 장비 구성은 사용자 측에서 수행하며,  
    AWS Site-to-Site VPN 및 라우팅 구성은 본 프로젝트 범위에 포함
  - AWS Directory Service (Managed Microsoft AD): 인증 주체

---

### 4.2 연동

#### 프로토콜 / 포트

**1) 사용자 → FSx**
- SMB: TCP 445
- NFS: TCP/UDP 2049

**2) FSx → Managed AD**
- Kerberos: TCP/UDP 88
- LDAP: TCP/UDP 389
- LDAPS: TCP 636
- DNS: TCP/UDP 53
- SMB: TCP 445
- RPC: TCP 135
- Dynamic RPC: TCP 49152–65535

---

#### 데이터 흐름

1. 사용자 → FSx 접근  
   → TCP 445 / 2049

2. FSx → AD 인증 요청  
   → 88, 389, 636, 53

3. FSx → AD 권한 확인  
   → 445, 135, 49152–65535

4. AD → FSx 응답

5. FSx → 사용자 접근 허용

---

### 4.3 운영 흐름

- 사용자가 FSx 접근 시 Kerberos 기반 인증이 수행되며,  
  FSx가 Managed AD와 통신하여 인증 및 권한을 검증함

- 배치 작업: 없음

- **장애 대응:**
  - FSx 상태 이상 시 CloudWatch 알람 기반 확인
  - AD 장애 시 인증 불가로 서비스 영향 발생
  - 필요 시 FSx 재시작 또는 AWS Support 요청

---

## 5. 비기능 요구사항

### 5.1 성능

- 사용자: 10명 동시 접속
- 처리량: 150Mbps 목표
- 확장: Manual

---

### 5.2 가용성

- AD만 Multi-AZ
- DR 없음
- 백업: FSx 스냅샷

---

### 5.3 관측성

- 로그: CloudWatch Logs
- 메트릭: CloudWatch

- **추가 모니터링:**
  - FSx 용량 임계치 알람
  - Throughput 사용량 모니터링

---

## 6. 제약 조건

- AWS Seoul 리전
- 네트워크: VPN
- IaC: Terraform
- 비용: 월 $800 이하

---

## 7. 보안

### 데이터

- 파일 데이터 전체
- 민감 데이터 없음

- **암호화:**
  - FSx 저장 데이터: AWS KMS 기반 암호화
  - 전송 구간: SMB/Kerberos 기반 암호화

---

### 인증

- LDAP + Kerberos 기반 인증
- MFA 없음

---

## 8. 네이밍 / 태깅

### 네이밍
- project: plvyx-nas
- env: prod
- service:
  - vpc
  - fsx
  - managed-ad

### 태깅

| 키 | 값 |
|----|-----|
| name | 네이밍과 동일 |
| env | prod |
| creator | ksjeon |
| version | 20260407 |

---

## 10. 참고 자료

- Managed AD 도메인: nas.plvyx.com
- Terraform Registry에 게시된 terraform-aws-modules 모듈 사용 예정, 활용 가능한 모듈이 없을 시 Documentation의 Example Usage 참고
- 아키텍처 경로: ./architecture/service-architecture.png, ./architecture/network-flow.png