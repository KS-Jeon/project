# 6. 리소스 네이밍 규칙 (패턴 기반)

리소스별로 개별 정의하지 않고, 아래 패턴을 기반으로 네이밍한다.

---

## 6.1 기본 패턴

<project>-<env>-<service>-<component>[-<detail>]

---

## 6.2 component 정의 기준

| 유형 | 예시 |
|------|------|
| 네트워크 | vpc, subnet, rt, igw, nat |
| 보안 | sg, role, policy |
| 컴퓨팅 | eks, nodegroup |
| 로드밸런서 | alb, tg |
| 데이터 | rds, fsx |
| 스토리지 | bucket |
| 로그 | log |

---

## 6.3 detail 사용 기준

detail은 아래 경우에만 사용한다:

- AZ 구분 (a, b, c)
- subnet type (public, private)
- nodegroup type (general, spot)
- 내부/외부 구분 (public, internal)

---

## 6.4 예시

- eks-prod-vpc
- eks-prod-subnet-private-a
- eks-prod-sg-node
- eks-prod-alb-public
- eks-prod-nodegroup-general
- app-prod-rds-mysql

---

## 6.5 서비스별 확장 규칙

새로운 서비스가 추가되더라도 아래 원칙을 따른다:

- service는 AWS / Azure / GCP 서비스 이름 기반으로 정의
- component는 리소스 역할 기반으로 정의
- detail은 필요한 경우에만 추가

예:
- lambda → app-prod-lambda-api
- opensearch → app-prod-opensearch-cluster