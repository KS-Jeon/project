# Architect Prompt

아래 파일들을 읽고 컨텍스트로 활용해 작업을 수행해줘.

- `AGENT.md`
- `agents/CLAUDE.md`
- `shared/policies/naming.md`
- `shared/policies/security-guardrails.md`
- `shared/policies/tagging.md`
- `shared/templates/spec/spec.template.md`
- `projects/<project-id>/input/request.md`

위 컨텍스트를 바탕으로 `CLAUDE.md`에 정의된 역할과 책임에 따라 작업을 수행해줘.
`spec.md`는 `spec.template.md` 구조를 그대로 따라 작성해줘.
---
# Devops Prompt

아래 파일들을 읽고 컨텍스트로 활용해 작업을 수행해줘.

- `AGENT.md`
- `agents/CODEX.md`
- `shared/policies/naming.md`
- `shared/policies/security-guardrails.md`
- `shared/policies/tagging.md`
- `projects/<project-id>/spec/*`
- `projects/<project-id>/qa/fix-request.md` (존재 시)

위 컨텍스트를 바탕으로 `CODEX.md`에 정의된 역할과 책임에 따라 작업을 수행해줘.
구현은 반드시 `spec/*` 기준으로 수행하고, 설계 변경은 하지 마.
작업 범위는 `projects/<project-id>` 하위로 제한해줘.
---
# QA Prompt

아래 파일들을 읽고 컨텍스트로 활용해 작업을 수행해줘.

- `AGENT.md`
- `agents/GEMINI.md`
- `shared/policies/naming.md`
- `shared/policies/security-guardrails.md`
- `shared/policies/tagging.md`
- `shared/templates/qa/report.template.md`
- `shared/templates/qa/fix-request.template.md`
- `projects/<project-id>/spec/*`
- `projects/<project-id>/output/*`
- `projects/<project-id>/qa/fix-request.md` (존재 시 참고)

위 컨텍스트를 바탕으로 `GEMINI.md`에 정의된 역할과 책임에 따라 검증을 수행해줘.
검증은 `spec` 및 정책 기준으로 수행하고, 설계 변경 없이 결과만 산출해줘.

- 구현 결과가 spec 및 정책을 충족하는지 검증
- Codex가 수정할 수 있는 명확한 작업 지시 생성 (fix-request)
- 사용자가 배포 여부를 판단할 수 있는 최종 보고서 제공 (report)