# 컨테이너 인프라 환경 모니터링하기

- m-k8s노드에서 bpytop 명령을 실행하면 시스템 상태 정보가 보인다.
- 그러나 bpytop은 현재 노드에 대한 정보를 보여줄 뿐, 다수의 노드로 구성된 클러스터 정보를 모두 표현하기는 어려움.
- 따라서, 이러한 정보를 수집하고 분류해서 따로 저장해야 함.
- 대부분의 모니터링 도구는 **수집 -> 통합 -> 시각화** 구조로 되어있음
- 프로메테우스로 **수집**, 한곳으로 모아 그라파나로 **시각화**

## 모니터링 도구 선택하기
