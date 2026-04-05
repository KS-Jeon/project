# Terraform Layout

이 디렉터리는 `agents/CODEX.md`의 최신 기준에 맞춰 module 기반으로 구성한다.

- `modules/`: 공통 인프라 모듈
- `envs/prod/`: 실제 배포 진입점

현재 스펙은 `prod` 단일 환경만 요구하므로 `envs/prod`만 구현했다.

실행 예시:

```bash
terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod init
terraform -chdir=projects/plvyx-nas/output/terraform/envs/prod plan
```

참고:

- 루트의 기존 `*.tf` 파일은 sandbox 제약으로 삭제되지 않아 block comment 처리했다.
- 실제로 Terraform이 읽어야 하는 활성 코드는 `modules/`와 `envs/prod/` 아래에만 있다.
