# 쿠버네티스 오브젝트

## 데몬셋

- 디플로이먼트의 replicas가 노드 수 만큼 정해져 있는 형태.
- 노드 하나당 파드 한 개만을 생성.
- 데몬셋을 언제 사용했을까?
  - Calico 네트워크 플러그인 생성
  - kube-proxy 생성
  - MetalLB의 스피커
  - 노드의 단일 접속지점으로 노드 외부와 통신하는 것

### 데몬셋 실습
1. MetalLB의 스피커가 각 노드에 분포돼 있는 상태 확인
  ```bash
    k get pod -n metallb-system -o wide
  ```
2. vagrant를 통해 워커노드의 개수를 1 증가
  ```Vagrantfile
    Vagrant.configure("2") do |config|
    N = 4 # max number of worker nodes
    Ver = '1.18.4' # Kubernetes Version to install
  ```
3. 다음의 명령어를 통해 새로운 워커 노드를 추가 
  ```bash
    vagrant up w4-k8s
  ```

4. 다음의 명령어를 통해, 변화하는 모습 확인
  ```bash
    k get pods -n metallb-system -o wide -w
    # -w 옵션은 watch의 약어로, 오브젝트 상태에 변화가 감지되면 해당 변화를 출력한다.
  ```

5. 추가한 노드에 설치된 스피커가 데몬셋이 맞는지 확인
  ```bash
    k get pods speaker-p2p2j -o yaml -n metallb-system
  ```