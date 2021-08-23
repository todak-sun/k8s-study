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

## 컨피그맵

- 설정을 목적으로 사용하는 오브젝트

### 실습

1. 테스트용 디플로이먼트 생성
  ```bash
    k create deployment cfgmap --image=sysnet4admin/echo-hname
  ```

2. `cfgmap` 을 로드밸런서(MetalLB)를 통해 노출하고 이름은 cfgmap-svc로 지정
  ```bash
    k expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80
  ```
3. 생성된 서비스의 IP 확인
  ```bash
    k get svc
  ```
4. 사전 구성되어 있는 컨피그맵의 기존 IP를 sed 명령을 사용해 변경
  ```bash
    cat ~/_Book_k8sInfra/ch3/3.4.2/metallb-l2config.yaml | grep 192.
    sed -i 's/11/21/;s/13/23/' ~/_Book_k8sInfra/ch3/3.4.2/metallb-l2config.yaml
    cat ~/_Book_k8sInfra/ch3/3.4.2/metallb-l2config.yaml | grep 192.
  ```
5. 변경된 컨피그맵 적용
  ```bash
    k apply -f ~/_Book_k8sInfra/ch3/3.4.2/metallb-l2config.yaml
  ```
6. MetalLB와 관련된 모든 파드 삭제
  ```bash
    k delete pod --all -n metallb-system
  ```
7. 새로 생성된 MetalLB의 파드 확인
  ```bash
    k get pod -n metallb-system
  ```
8. 기존 노출한 서비스를 삭제하고 동일한 이름으로 다시 생성
  ```bash
    k delete service cfgmap-svc
    k expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80
  ```
9. 변경된 설정대로 MetalLB 서비스의 IP가 변경되었는지 확인
  ```bash
    k get svc
  ```
10. 변경된 IP로 브라우저를 통해 접속
11. 삭제
  ```bash
    k delete deployment cfgmap
    k delete service cfgmap-svc
  ```