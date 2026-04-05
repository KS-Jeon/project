# AGENT.md
# IDE-Based Agent Harness Operating Model (Monorepo Edition)

## 1. 목적
본 문서는 IDE 환경에서 Claude, Codex, Gemini 에이전트를 활용하여 클라우드 인프라를 설계, 구현, 검증하기 위한 작업 흐름과 역할을 정의한다.

본 구조는 자동 파이프라인이 아닌, 사용자가 IDE에서 직접 에이전트를 호출하여 수행하는 수동 오케스트레이션 방식으로 운영된다.

목표:
- 프로젝트 단위 IaC 설계 및 구현 표준화
- 설계 / 구현 / QA 역할 분리
- 코드와 문서의 정합성 유지
- 재사용 가능한 DevOps 작업 구조 확립

---

## 2. 모노레포 구조

repo-root/
├─ README.md
├─ AGENT.md
├─ agents/
│  ├─ CLAUDE.md
│  ├─ CODEX.md
│  └─ GEMINI.md
├─ projects/
│  ├─ <project-id>/
│  │  ├─ inputs/
│  │  ├─ spec/
│  │  ├─ output/
│  │  ├─ qa/
│  │  └─ harness/
│  └─ README.md
└─ shared/

---

## 3. 프로젝트 스코프 규칙

- PROJECT_ID: 프로젝트 식별자
- PROJECT_ROOT: projects/<project-id>

모든 작업은 반드시 PROJECT_ROOT 하위에서 수행한다.

규칙:
- 타 프로젝트 디렉터리 접근 금지
- spec / output / qa 혼합 금지
- shared 변경은 별도 검토 후 수행

---

## 4. 역할 구성

- Claude: 아키텍처 설계 및 명세 정의
- Codex: 구현 및 코드 생성
- Gemini: QA 및 검증 문서 작성
- Human: 최종 판단 및 반영

---

## 5. 작업 흐름 (IDE 기반)

1. inputs 작성 (요구사항 / 아키텍처 / request.md)
2. Claude 호출 → spec 생성
3. Codex 호출 → output 생성 + README 갱신
4. Local validation 수행 (개발자 실행)
5. Gemini 호출 → QA 문서 생성
6. 결과 검토 후 Git 반영

---

## 6. Local Validation

검증은 자동 파이프라인이 아닌, 사용자가 직접 수행한다.

예시:

Terraform:
- terraform fmt -check
- terraform validate

Helm:
- helm lint

Kubernetes:
- kubeconform

Security:
- tfsec

---

## 7. 문서 관리 규칙

### 입력 문서
- inputs/: 요구사항 및 아키텍처 원본

### 설계 산출물
- spec/: Claude 결과

### 구현 산출물
- output/: Codex 결과

### QA 산출물
- qa/: Gemini 결과

---

## 8. README 관리

- 루트 README:
  - Claude가 프로젝트 목록 관리

- 프로젝트 README:
  - Codex가 작성 및 유지

---

## 9. 핵심 원칙

- 설계 → 구현 → 검증 순서 유지
- 에이전트 역할을 혼합하지 않는다
- 모든 산출물은 Git으로 추적 가능해야 한다
- 문서는 항상 코드와 일치해야 한다