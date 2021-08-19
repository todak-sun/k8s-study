# 쿠버네티스 연결을 담당하는 서비스

- 쿠버네티스의 서비스
  - 외부에서 쿠버네티스 클러스터에 접속하는 방법
  - 외부 사용자가 파드를 이용하는 방법
  - 소비를 위한 도움을 제공한다는 관점

## 가장 간단하게 연결하는 노드포트

- 모든 워커 노드의 특정 포트(노드포트)를 열고, 여기로 오는 모든 요청을 노드포트 서비스로 전달.
- 노드포트 서비스는 해당 업무를 처리할 수 있는 파드로 요청을 전달.

### 실습 - 노드포트 서비스로 외부에서 접속하기

1. 디플로이먼트로 파드 생성
  ```bash
    k create deployment np-pods --image=sysnet4admin/echo-hname
  ```
2. 배포된 파드 확인
  ```bash
    k get po
  ```
3. `kubectl create`로 노드포트 서비스 생성.
  ```
    k create -f nodeport.yaml
  ```
4. 서비스 확인
  ```
    k get svc
  ```
5. 쿠버네티스 클러스터의 워커 노드 IP를 확인
  ```
    k get nodes -o wide
  ```
6. 호스트PC에서 웹 브라우저를 띄우고, 위에서 확인한 IP에 30000번 포트(노드포트의 포트 번호)로 접속 시도
  - 파드가 하나이므로, 3개의 워커 노드 모두 동일한 파드로 접속

### 실습 - 부하분산 테스트하기

1. `powershell` 명령 창을 띄우고 다음 명령어 실행
  ```powershell
    $i=0; while($true)
    {
      % { $i++; write-host -NoNewline "$i $_" }
      (Invoke-RestMethod "http://192.168.1.101:30000")-replace '\n', " "
    }
  ```
2. 파드를 3개로 증가
  ```bash
    k scale deployment np-pods --replicas=3
  ```
3. 파워셸 명령 창을 확인하면, 파드 이름에 배포된 파드 3개가 돌아가면서 표시된다.
   - 어떻게 추가된 파드를 외부에서 추적해 접속할까?
   - 노드포트의 오브젝트 스펙에 적힌 np-pods와 디플로이먼트의 이름을 확인해 동일하면 같은 파드라고 간주한다.

### expose로 노드포트 서비스 생성

- 오브젝트 스펙 파일이 아닌, 명령어로 서비스를 생성하는 방법

1. `expose` 명령어 사용
  ```bash
    k expose deployment np-pods --type=NodePort --name=np-svc-v2 --port=80
  ```
2. 생성된 서비스 확인
  ```bash
    k get svc
  ```
  - expose를 사용하면 노드포트의 포트 번호를 지정할 수 없다. 포트 번호는 30000 ~ 32767에서 임의 지정된다.
3. 호스트에서 접속해, 배포된 파드 중 하나의 이름이 웹 브라우저에 표시되는지 확인
4. 삭제
  ```bash
    k delete deployment np-nodes
    k delete svc np-svc
    k delete svc np-svc-v2
  ```

## 사용 목적별로 연결하는 인그레스

- 노드포트 서비스는 포트를 중복 사용할 수 없다.
- 1개의 노드포트에 1개의 디플로이먼트만 적용 가능하다.

### 인그레스(Ingress)
- 고유한 주소를 제공해 사용 목적에 따라 다른 응답을 제공할 수 있다.
- 트래픽에 대한 L4/L7 로드밸런서와 보안 인증서를 처리하는 기능을 제공한다.

### NGINX 인그레스 컨트롤러(NGINX Ingress controller)
1. 사용자는 노드마다 설정된 노드포트를 통해 노드포트 서비스로 접속한다.
2. 노드포트 서비스를 NGINX 인그레스 컨트롤러로 구성한다.
3. NGINX 인그레스 컨트롤러는 사용자의 접속 경로에 따라 적합한 클러스터 IP 서비스로 경로를 제공한다.
4. 클러스터 IP 서비스는 사용자를 해당 파드로 연결해 준다.
- 인그레스 컨트롤러는 파드와 직접 통신할 수 없다.
- 인그레스 컨트롤러가 파드와 통신하기 위해서는 노드포트 또는 로드밸런서 서비스와 연동되어야 한다.
- 따라서, 노드포트로 이를 연동한다.

### 실습

1. 테스트용으로 디플로이먼트 2개를 배포한다.
  ```bash
    k create deployment in-hname-pod --image=sysnet4admin/echo-hname
    k create deployment in-ip-pod --image=sysnet4admin/echo-ip
  ```
2. 배포된 파드의 상태 확인
  ```bash
    k get po
  ```
3. NGINX 인그레스 컨트롤러 설치.
  ```bash
    k apply -f ingress-nginx.yaml
  ```
4. NGINX 인그레스 컨트롤러의 파드가 배포되었는지 확인
  ```bash
    k get po -n ingress-nginx
  ```
  - NGINX 인그레스 컨트롤러는 default 네임스페이스가 아닌 ingress-nginx 네임스페이스에 속하므로, -n ingress-nginx 옵션을 추가한다.
5. 인그레스 설정파일 적용
  ```bash
    k apply -f ingress-config.yaml
  ```
6. 인그레스 설정 파일이 제대로 등록됐는지 확인
  ```bash
    k get ingress
  ```  
7. 인그레스에 요청한 내용이 확실히 적용되었는지 yaml로 확인
  ```bash
    k get ingress -o yaml
  ```
8. 외부에서 NGINX 인그레스 컨트롤러에 접속할 수 있도록 노드포트 서비스로 NGINX 인그레스 컨트롤러 노출
  ```bash
    k apply -f ingress.yaml
  ```
9. 노드포트 서비스로 생성된 NGINX 인그레스 컨트롤러 확인
  ```bash
    k get svc -n ingress-nginx
  ```
10. expose 명령어로 deployment 노출
  ```bash
    k expose deployment in-hname-pod --name=hname-svc-default --port=80,443
    k expose deployment in-ip-pod --name=ip-svc --port=80,443
  ```
  - 클러스터 내부에서만 사용하는 파드를 클러스터 외부에 노출할 수 있는 구역으로 옮기는 작업.
  - 내부와 외부 네트워크를 분리해 관리하는 DMZ와 유사한 기능
  - 각 방에 있는 물건을 외부로 내보내기 전에 공용 공간인 거실로 모두 옮기는 것과 유사

11. 디플로이먼트가 서비스에 정상적으로 노출되어있는지 확인
  ```bash
    k get svc
  ```
12. 브라우저로 접속시도
  - http://{node-ip}:30100
  - http://{node-ip}:30100/ip
  - https://{node-ip}:30101
  - https://{node-ip}:30101/ip

13. 자원 모두 삭제
  ```bash
    k delete deployments.apps in-hname-pod
    k delete deployments.apps in-ip-pod
    k delete service hname-svc-default
    k delete service ip-svc
    clear
    k delete -f ingress-nginx.yaml
    k delete -f ingress-config.yaml
  ```
## 클라우드에서 쉽게 구성 가능한 로드밸런서

- 앞서보낸 방식은 매우 비효율적이다.
  - 들어오는 요청을 모두 워커 노드의 노드포트를 통해 노드포트 서비스로 이동
  - 이를 다시 쿠버네티스의 파드로 전달

- 쿠버네티스에서는 로드밸런서(LoadBalancer)라는 서비스 타입을 제공한다.
- 로드밸런서를 사용하기 위해서는 로드밸런서를 구현해 둔 서비스업체의 도움을 받아야한다.
- 클라우드에서 제공하는 로드밸런서 서비스를 사용하면, 외부와 통신할 수 있는 IP가 부여되고, 외부와 통신할 수 있으며 부하도 분산된다.

## 온프레미스에서 로드밸런서를 제공하는 MetalLB

- 온프레미스에서 로드밸런서를 사용하려면, 내부에 로드밸런서 서비스를 받아줄 구성이 필요하다.
- MetalLB는 베어메탈(bare metal, 운영체제가 설치되지 않은 하드웨어)로 구성된 쿠버네티스에서도 로드밸런서를 사용할 수 있게 고안된 프로젝트다.
- MetalLB는 특별한 네트워크 설정이나 구성없이, 기존 L2네트워크(ARP/NDP)와 L3(네트워크BGP)로 로드밸런서를 구현한다.
- 실습은 MetalLB의 L2 네트워크로 로드밸런서를 구현한다.

### MetalLB
- MetalLB 컨트롤러는 작동 방식(Protocal, 프로토콜)을 정의하고 EXTERNAL-IP를 부여해 관리한다.
- MetalLB 스피커(speaker)는 정해진 작동 방식(L2/ARP, L3/BGP)에 따라 경로를 만들 수 있도록 네트워크 정보를 광고하고 수집해 각 파드의 경로를 제공한다.
- 이때 L2는 스피커 중에서 리더를 선출해 경로 제공을 총괄한다.

### 실습
1. 디플로이먼트를 통해 파드를 생서하고, `scale` 명령으로 파드를 3개로 늘린다.
  ```bash
    k create deployment lb-hname-pods --image=sysnet4admin/echo-hname
    k scale deployment lb-hname-pods --replicas=3
    k create deployment lb-ip-pods --image=sysnet4admin/echo-ip
    k scale deployment lb-ip-pods --replicas=3
  ```
2. 두 종류의 파드가 총 6개 배포됐는지 확인.
  ```bash
    k get po -o wide
  ```
3. metallb 구성
  ```bash
    k apply -f metallb.yaml
  ```
4. metallb 구성 확인
  ```bash
    k get po -n metallb-system -o wide
  ```
  - 파드가 5개(controller 1개, speaker 4개), IP, 상태 확인
5. MetalLB 설정 적용
  ```bash
    k apply -f metallb-l2config.yaml
  ```
6. configmap 확인
  ```bash
    k get configmaps -n metallb-system
  ```

7. `-o yaml` 옵션을 통해, 설정이 올바르게 적용됐는지 다시 확인
  ```bash
    k get configmaps -n metallb-system -o yaml
  ```
8. 각 디플로이먼트를 로드밸런서 서비스로 노출
  ```bash
    k expose deployment lb-hname-pods --type=LoadBalancer --name=lb-hname-svc --port=80
    k expose deployment lb-ip-pods --type=LoadBalancer --name=lb-ip-svc --port=80
  ```
9. 서비스 확인
  ```bash
    k get svc
  ```
10. EXTERNAL-IP 확인 및 브라우저를 통해 접속 시도

11. 로드밸런서 기능 정상 작동여부 확인
  ```powershell
    $i=0; while($true)
    {
      % { $i++; write-host -NoNewline "$i $_" }
      (Invoke-RestMethod "http://192.168.1.11")-replace '\n', " "
    }
  ```
12. `scale` 명령으로 파드 6개로 증가
  ```bash
    k scale deployment lb-hname-pods --replicas=6
  ```

13. 실습내용 삭제
  ```bash
    k delete deployments.apps lb-hname-pods
    k delete deployments.apps lb-ip-pods
    k delete service lb-hname-svc
    k delete service lb-ip-svc
  ```

## 부하에 따라 자동으로 파드 수를 조절하는 HPA

- 쿠버네티스는 부하량에 따라 디플로이먼트의 파드 수를 유동적으로 관리하는 기능을 제공한다.
- 이것을 HPA(Horizontal Pod Autoscaler)라고 한다.

### 실습

1. 디플로이먼트 생성
  ```bash
    k create deployment hpa-hname-pods --image=sysnet4admin/echo-hname
  ```

2. expose를 실행해, 로드밸런서 서비스로 설정
  ```bash
    k expose deployment hpa-hname-pods --type=LoadBalancer --name=hpa-hname-svc --port=80
  ```

3. 로드밸런서 서비스와 부여된 IP 확인
  ```bash
    k get svc
  ```

4. `top`을 활용해 부하 확인
  ```bash
    k top pods
  ```
  - 자원을 요청하는 설정이 없다는 에러 발생.
  - HPA가 자원을 요청할 때, Metrics-Server를 통해 계측값을 전달 받는다.
  - 하지만, 현재 메트릭 서버가 없기 때문에 에러가 발생한다.

5. 오브젝트 스펙을 통해 메트릭 서버 설치
  ```bash
    k create -f metrics-server.yaml
  ```
6. 메트릭 서버 설정 후, 다시 한번 `top` 명령어 실행
  ```bash
    k top pods
  ```
  - scale 기준 값이 설정돼 있지 않아, 파드 증설 시점을 알 수 없다.
  - 파드에 부하가 걸리기 전에 scale이 실행될 수 있게, deployment를 수정한다.
7. `edit` 명령어를 실행해 배포된 디플로이먼트 내용 확인
  ```bash
    k edit deployment hpa-hname-pods
  ```
  - m은 milliunits의 약어로, 1000m은 1개의 CPU를 의미한다.
  - 10m은 파드의 CPU 0.01 사용을 기준으로 파드 증설
  - 순간적으로 한쪽 파드로 부하가 몰릴 경우를 대비해 CPU 사용 제한을 0.05로 제한
  ```yaml
    resources:
      requests:
        cpu: "10m"
      limits:
        cpu: "50m"
  ```
8. 일정시간이 지나면 스펙이 변경돼 새로운 파드가 생성된다.
  ```bash
    k top pods
  ```
9. autoscale을 설정
  ```bash
    k autoscale deployment hpa-hname-pods --min=1 --max=30 --cpu-percent=50
  ```
  - min은 최소 파드의 수를 의미
  - max는 최대 파드의 수를 의미
  - percent는 CPU 사용량이 50%를 넘게되면 autoscale 하겠다는 뜻

```powershell
$i=0; while($true)
{
  % { $i++; write-host -NoNewline "$i $_" }
  (Invoke-RestMethod "http://192.168.1.11")-replace '\n', " "
}
```