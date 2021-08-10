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
  ```
    k get svc -n ingress-nginx
  ```