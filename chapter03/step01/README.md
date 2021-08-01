# 쿠버네티스 구성하기

## 구성하기
- 각 파일에 남긴 주석을 참고.

## 확인
- vagrant up
- m-k8s ssh로 접속
- kubectl get nodes
- kubectl get pods --all-namespace
  - 기본 네임스페이스 default 외 모든 것을 표시

## 파드 배포하는 순서에 따른 요소들의 역할

### 마스터노드
1. kubectl
   - 쿠버네티스 클러스터에 명령을 내리는 역할
2. API 서버
   - 쿠버네티스 클러스터의 중심 역할을 하는 통로.
   - 주로 상태 값을 저장하는 etcd와 통신하지만, 그 밖 요소들 또한 API 서버를 중심에 두고 통신한다.
3. etcd
   - 구성 요소들의 상태 값이 모두 저장되는 곳
   - etcd 외의 다른 구성 요소는 상태값을 관리하지 않는다.
   - 분산 저장이 가능한 key-value 저장소이므로, 복제해 여러 곳에 저장해 두면 하나의 etcd에서 장애가 나더라도 시스템의 가용성을 확보할 수 있다.

4. 컨트롤러 매니저
   - 쿠버네티스 클러스터의 오브젝트 상태를 관리한다.
     - 워커 노드에서 통신이 되지 않는 경우, 상태 체크와 복구는 노드 컨트롤러
     - 레플라카셋 컨트롤러는 레플리카셋에 요청받은 파드 개수대로 파드를 생성

5. 스케줄러
   - 노드의 상태와 자원, 레이블, 요구 조건 등을 고려해 파드를 어떤 워커 노드에 생성할 것인지를 결정하고 할당.
   - 파드를 조건에 맞는 워커 노드에 지정하고, 파드가 워커 노드에 할당되는 일정을 관리

### 워커 노드

6. kubelet
   - 파드의 구성 내용(PodSpec)을 받아서 컨테이너 런타임으로 전달
   - 파드 안의 컨테이너들이 정상적으로 작동하는지 모니터링

7. 컨테이너 런타임(CRI, Container Runtime Interface)
   - 파드를 이루는 컨테이너 실행을 담당.
   - 파드 안에서 다양한 종류의 컨테이너가 문제 없이 작동하게 만드는 표준 인터페이스

8. 파드
   - 한 개 이상의 컨테이너로 단일 목적의 일을 하기 위해 모인 단위
   - 웹 서버 역할을 하거나, 로그/데이터 분석을 할 수도 있다.
   - 파드는 **언제라도 죽을 수 있는 존재**다.
 

### 선택 가능한 구성 요소

9. 네트워크 플러그인
10. CoreDNS

## 파드의 생명주기로 쿠버네티스 구성 요소 살펴보기

1. kubectl을 통해 API 서버에 파드 생성 요청
2. (업데이트가 있을 때마다 매번) API 서버에 전달된 내용이 있으면 API 서버는 etcd에 전달된 내용을 모두 기록해 클러스터의 상태 값을 최신으로 유지(etcd 기록)
3. API 서버에 파드 생성이 요청된 것을 컨트롤러 매니저가 인지하면 컨트롤러 매니저는 파드를 생성하고, 이 상태를 API 서버에 전달, 이 단계에서는 생성된 파드가 어떤 워커 노드에 배치될지 모른다.
4. 스케줄러가 API 서버로부터 파드가 생성됐다는 정보를 인지한다. 스케줄러는 생성된 파드를 어떤 워커 노드에 적용할지 조건을 고려해 결정하고, 워커 노드에 파드를 띄우도록 요청한다.
5. API 서버에 전달된 정보대로 지정한 워커 노드에 파드가 속해 있는지 스케줄러가 kubelet으로 확인
6. kubelet에서 컨테이너 런타임으로 파드 생성을 요청
7. 파드가 생성
8. 파드가 사용 가능한 상태가 된다.

쿠버네티스는 작업을 순서대로 진행하는 워크플로(workflow) 구조가 아니라,
선언적인(declarative) 시스템 구조를 가지고 있다. 즉, 각 요소가 추구하는 상태(desired status)를 선언하면, 현재 상태(current status)와 맞는지 점검하고 그것에 맞추려고 노력하는 구조로 되어있다.

## 쿠버네티스 구성요소 기능 검증

### kubectl

- 쿠버네티스 클러스터의 외부에서도 kubectl을 사용할 수 있으며, 명령을 내릴 수 있다. 이를 검증해보자.

1. w3-k8s에 접속해본다.
2. kubectl get nodes를 실행
   => w3에서는 kubectl이 API 서버의 접속 정보를 모르기 때문에, 제대로 작동하지 않는다.
3. 쿠버네티스 클러스터의 정보를 마스터 노드에서 scp 명령으로 w3 현재 디렉토리에 받아온다.
   ```bash
   >> w3
   scp root@192.168.1.10:/etc/kubernetes/admin.conf .
   kubectl get nodes --kubeconfig admin.conf
   ```

### kubelet

- kubelet은 파드의 생성, 상태 관리, 복구 등을 담당하는 매우 중요한 구성요소다.
- kubelet에 문제가 생기면 파드가 정상적으로 관리되지 않는다.

1. 마스터 노드에서 파드를 배포한다
   ```bash
   kubectl create -f ~/_Book_k8sInfra/ch3/3.1.6/nginx-pod.yaml
   ```
2. 파드가 배포된 노드의 위치를 찾는다
   ```bash
   kubectl get pod -o wide
   ```
3. 파드가 배포된 노드에서 다음의 명령어를 통해 kubelet의 서비스를 멈춘다.
   ```bash
   systemctl stop kubelet
   ```
4. 마스터 노드로 돌아가 방금 생성한 pod를 삭제한다
   ```bash
   kubectl delete pod nginx-pod
   ```
5. 오랜 시간이 지나도, pod는 삭제되지 않는다. 파드의 상태를 확인하면 Terminating에서 변하지 않고 있음을 확인할 수 있다.
6. 다시 w3로 돌아가 kubelet의 시스템을 시작시키면, 다시 정상적으로 작동함을 알 수 있다.

### kube-proxy

- kubelet이 파드의 상태를 관리한다면, kube-proxy는 파드의 통신을 담당한다. 
- config.sh 파일에서 br_netfilter 커널 모듈을 적재하고 iptables를 거쳐 통신하도록 설정했다.
  ```Vagrantfile
   cat <<EOF >  /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-ip6tables = 1
   net.bridge.bridge-nf-call-iptables = 1
   EOF
   modprobe br_netfilter 
  ```

1. 마스터 노드에 아래의 명령어를 통해 파드를 배포한다
   ```bash
   kubectl create -f ~/_Book_k8sInfra/ch3/3.1.6/nginx-pod.yaml
   ```
2. kubectl get pod -o wide 명령어로 파드의 IP, 워커 노드를 확인한다.
3. curl 명령어로, nginx 웹 서버 메인 페이지 내용을 확인한다.
4. pod가 배포되어 있는 노드로 접속해, 아래의 명령어를 통해 br_netfilter 모듈을 제거한다.
   ```bash
   modprobe -r br_netfilter
   systemctl restart network
   ```
5. 마스터 노드로 돌아가, curl 요청을 보내면 응답이 오질 않는다.
   => kube-proxy가 이용하는 br_netfilter에 문제가 있어, 파드의 nginx 웹 서버와의
   통신만이 정상적으로 이루어지지 않는 상태이다. 따라서, STATUS는 정상적으로
6. 아래의 명령어를 통해 다시 복구 시킨다
   ```bash
   modprobe br_netfilter
   reboot
   ```
7. 일정 시간이 지나 파드의 상태를 확인하면, RESTART가 1오르고, IP가 변경된 것을 확인할 수 있다.