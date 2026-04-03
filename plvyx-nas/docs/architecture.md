# PLAVYX NAS 서비스 아키텍처 명세서

## 1. 문서 목적

본 문서는 PLAVYX NAS 서비스의 상위 서비스 아키텍처와 네트워크 흐름을 정의하기 위한 문서이다.  
현재 구성은 AWS Cloud 상의 `Amazon FSx for NetApp ONTAP`를 스토리지 계층으로 사용하고, 인증 및 디렉터리 서비스는 `AWS Managed Microsoft AD`를 통해 제공하는 구조를 기준으로 정리하였다.

## 2. 아키텍처 개요

본 아키텍처는 사내 업무 환경과 AWS Cloud 간의 Site-to-Site VPN 연결을 기반으로 동작한다.  
스토리지 서비스는 AWS 내부의 프라이빗 서브넷에 배치되며, 사용자 인증과 파일 서비스 권한 관리는 AWS Managed Microsoft AD와 연동하여 처리한다.

핵심 설계 방향은 다음과 같다.

- 스토리지와 인증 시스템을 모두 프라이빗 네트워크 내에 배치한다.
- 액티브 디렉토리 서비스는 다중 서브넷에 이중화하여 고가용성을 확보한다.
- 파일 서비스 접근은 인증 체계와 분리하지 않고 AD 기반으로 일관되게 통제한다.
- 외부 구간과 AWS 구간 사이에는 암호화된 보안 연결을 적용한다.

## 3. 서비스 아키텍처

![서비스 아키텍처](./image/service-architecture.png)

### 3.1 구성 설명

서비스 아키텍처는 다음의 계층으로 구성된다.

| 구분 | 구성 요소 | 설명 |
|---|---|---|
| 외부/물리 구간 | 사내 업무 환경 | NAS를 사용하는 사용자가 위치하는 영역 |
| 연결 구간 | IPSec VPN 연결 | 온프레미스와 AWS 간의 암호화된 연결 경로 |
| 클라우드 스토리지 | Amazon FSx for NetApp ONTAP | NAS 볼륨, SVM, 저장 용량을 제공하는 핵심 스토리지 서비스 |
| 인증/권한 | AWS Managed Microsoft AD | 사용자 인증, 도메인 조인, 파일 권한 제어를 담당하는 디렉터리 서비스 |

### 3.2 동작 개념

1. 사용자는 사내 업무 환경에서 NAS 서비스에 접근한다.
2. 접근 요청은 VPN 연결 구간을 통해 AWS Cloud로 전달된다.
3. 파일 저장 및 공유는 Amazon FSx for NetApp ONTAP에서 처리한다.
4. 인증 및 접근 권한 검증은 AWS Managed Microsoft AD를 통해 수행한다.

## 4. 네트워크 흐름도

![네트워크 흐름도](./image/network-flow.png)

### 4.1 구성 요소

네트워크 흐름도 기준의 주요 구성 요소는 다음과 같다.

| 영역 | 구성 요소 | 설명 |
|---|---|---|
| VPC | AWS 전용 네트워크 영역 | NAS 서비스 전체가 배치되는 논리적 네트워크 |
| FSx Subnet | FSx for ONTAP 배치 구간 | 스토리지 리소스를 외부에 직접 노출하지 않는 서브넷 |
| AD Subnet x 2 | AWS Managed AD 배치 구간 | 서로 다른 서브넷에 도메인 컨트롤러를 분산 배치 |
| FSx ONTAP 내부 리소스 | SVM Instance, Capacity Pool, Primary SSD | 파일 서비스, 저장 용량, 성능 계층을 담당 |
| Managed AD 내부 리소스 | Domain Controller x 2 | 인증, 디렉터리 조회, 정책 적용, 복제를 수행 |

### 4.2 흐름 설명

다이어그램의 번호 기준 흐름은 다음과 같다.

1. 사용자는 NAS 서비스 접근을 위해 `AWS Managed Microsoft AD`에 인증을 수행하고 Kerberos Ticket을 발급받는다.
2. 실제 파일 데이터 접근은 `Amazon FSx for NetApp ONTAP`의 SVM 인스턴스에서 처리되며, 저장 계층은 Primary SSD와 Capacity Pool을 기반으로 동작한다.
3. 두 개의 `AWS Managed Microsoft AD Domain Controller`는 서로 간 복제를 수행해 디렉터리 정보와 인증 상태를 일관되게 유지한다.
4. `FSx for ONTAP`은 클라이언트가 전달한 인증 정보를 기반으로 `AD Domain Controller`에 사용자 및 그룹 정보를 조회하여 접근 권한을 검증한 후 데이터 접근을 허용한다.

## 5. 예상 접근 시나리오

1. 사용자는 NAS 공유 경로나 애플리케이션을 통해 파일 접근을 요청하며, 사전에 `AWS Managed Microsoft AD`를 통해 인증(Kerberos 등)을 완료하고 인증 정보를 보유한다.
2. 접근 요청은 보안 통제 구간을 거쳐 AWS VPC 내부의 `Amazon FSx for NetApp ONTAP`으로 전달된다.
3. `FSx for ONTAP`은 SVM 인스턴스에서 요청을 처리하기 전에 클라이언트가 전달한 인증 정보를 기반으로 `AWS Managed Microsoft AD Domain Controller`에 사용자 및 그룹 정보를 조회하여 접근 권한을 검증한다.
4. 두 `Domain Controller`는 복제된 디렉터리 정보를 기반으로 일관된 인증/디렉터리 상태를 유지하며, `FSx`는 검증 결과에 따라 접근 허용 여부를 결정한다.
5. 검증이 완료된 경우에만 사용자는 허용된 파일 또는 디렉터리에 접근할 수 있으며, 데이터는 Primary SSD와 Capacity Pool 정책에 따라 저장 및 관리된다.