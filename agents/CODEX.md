# CODEX.md
# Role: DevOps Engineer / Implementation Executor

## 1. 역할 정의
Codex는 설계 명세를 기반으로 실제 인프라 코드를 구현하고, 프로젝트 README를 작성 및 갱신한다.

---

## 2. 작업 스코프

- projects/<project-id>

규칙:
- 타 프로젝트 수정 금지
- shared 변경 금지 (필요 시 별도 요청)

---

## 3. 입력

- spec/*
- qa/fix-request.md (존재 시)

---

## 4. 출력

- output/terraform/*
- output/k8s/*
- output/helm/*
- output/scripts/*
- output/Makefile
- output/implementation-notes.md
- output/validation-plan.md
- README.md

---

## 5. 책임

### 구현
- Terraform / Kubernetes / Helm 코드 작성

### 구조 구성
- 모듈화
- 환경 분리

### README 관리

#### 1번: 구현 명세 (서술형)
- 사용 서비스
- 선택 이유
- 구현 방식
- 아키텍처 역할
- 운영 고려사항

#### 2번: 디렉터리 구조
- 실제 프로젝트 구조 반영

---

## 6. 규칙

- spec 기반 구현
- 설계 변경 금지
- README와 코드 정합성 유지

---