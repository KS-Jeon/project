# Tagging Policy

## 1. 목적
본 문서는 클라우드 리소스에 태그를 적용하기 위한 권장 기준을 정의한다.

태그는 비용 관리, 운영 추적, 변경 이력 관리, 책임 소재 식별을 위해 사용되며,
고객 요구사항 및 조직 정책에 따라 유연하게 확장될 수 있다.

---

## 2. 기본 원칙

- 태그는 "필수"가 아닌 "권장" 기준으로 정의한다
- 프로젝트 또는 고객 요구사항에 따라 자유롭게 확장 가능하다
- 동일 프로젝트 내에서는 태그 키와 형식을 일관되게 유지한다
- 태그 값은 명확하고 추적 가능한 형태로 작성한다

---

## 3. 권장 태그 (Recommended Tags)

아래 태그는 기본적으로 사용하는 것을 권장한다.

| Key     | 설명             | 예시        |
|---------|------------------|-------------|
| name    | 리소스 이름      | eks-prod-vpc |
| env     | 환경             | dev / prod |
| creator | 생성자           | ksjeon |
| version | 생성 또는 변경 버전 | 20260405 |

---

## 4. 태그 정의 기준

### name
- naming.md 규칙을 따른다
- 리소스 식별 가능해야 한다

### env
- dev / stage / prod 중 하나 사용
- 환경 구분이 명확해야 한다

### creator
- 리소스를 생성한 사람 또는 주체
- 개인 또는 팀 이름 사용 가능

### version
- YYYYMMDD 형식 권장
- 리소스 생성 또는 주요 변경 기준으로 업데이트

---

## 5. 추가 태그 (선택)

필요 시 아래와 같은 태그를 추가할 수 있다.

| Key        | 설명 |
|------------|------|
| service    | 서비스 유형 |
| cost-center | 비용 관리용 |
| project    | 프로젝트 이름 |
| description | 리소스 설명 |

---

## 6. Terraform 적용 예시

locals {
  common_tags = {
    name    = "eks-prod-vpc"
    env     = "prod"
    creator = "ksjeon"
    version = "20260405"
  }
}

resource "aws_vpc" "main" {
  tags = local.common_tags
}
.