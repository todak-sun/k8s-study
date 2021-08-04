# 쿠버네티스 기본 사용법 배우기

## 파드를 생성하는 방법

1. kubectl run 활용
  ```bash
    kubectl run nginx-pod --image=nginx 
           # run 다음은 pod의 이름, image는 사용할 이미지의 이름
    > pod/ngingx-pod created
  ```
2. kubectl create 활용
  ```bash
    kubectl create nginx --image=nginx
    # ERROR!
    kubectl create deployment dpy-nginx --image-nginx
    > deployment.apps/dpy-nginx created 
  ```
3. 확인
  ```bash
    kubectl get pods -o wide
  ```
  - 확인을 해보면 두 파드 모두 정상적으로 생성 되었음을 알 수 있다.
  - 두 파드에 요청을 보내보면, 제대로 응답을 가져오는 것을 알 수 있다.

4. run vs create
  - run으로 파드를 생성하면 단일 파드 1개만 생성되고 관리된다.
  - create deployment로 파드를 생성하면 디플로이먼트(Deployment)라는 관리 그룹 내에서 파드가 생성된다.

## 오브젝트란

쿠버네티스를 사용하는 관점에서 파드와 디플로이먼트는 스펙(spec)과 상태(status)등의 값을 가지고 있다.
이러한 값을 가지고 있는 파드와 디플로이먼트를 개별 속성을 포함해 부르는 단위를 오브젝트(Object)라고 한다.

### 기본 오브젝트

- 파드:
  - 쿠버네티스에서 실행되는 최소 단위
  - 독립적인 공간와 사용 가능한 IP를 가지고 있다.
  - 1개의 파드는 1개 이상의 컨테이너를 가지고 있다.
- 네임스페이스:
  - 클러스터에서 사용되는 리소스들을 구분해 관리하는 그룹
- 볼륨:
  - 파드가 생성될 때 파드에서 사용할 수 있는 디렉터리를 제공
  - 파드는 영속되는 개념이 아니기 때문에, 제공되는 디렉터리도 임시로 사용한다.
  - 하지만, 볼륨 오브젝트를 활용하면 파드가 데이터의 저장과 보존이 가능하다.
- 서비스:
  - 파드는 클러스터 내에서 유동적이기 때문에 접속 정보가 고정되어 있지 않다.
  - 파드 접속을 안정적으로 유지할 수 있도록 서비스를 통해 내/외부로 연결할 수 있게 돕는 오브젝트.
  - 쿠버네티스 외부에서 내부로 접속할 때, 내부가 어떤 구조로 돼 있는지, 파드의 상태와 관계 없이 논리적으로 연결한다.
  - 기존 인프라에서 로드밸런서, 게이트웨이와 비슷한 역할을 한다.
- 디플로이먼트:
  - 기본 오브젝트만을 사용하는데는 한계가 있어, 이를 효율적으로 작동하도록 기능들을 조합하고 추가해 구현한 것이 디플로이먼트다.
  - 쿠버네티스에서 가장 많이 쓰이는 오브젝트다.
  - 파드에 기반을 두고 있으며, 레플리카셋 오브젝트를 합쳐 놓은 형태이다.
  - API 서버와 컨트롤러 매니저는 단순히 파드가 생성되는 것을 감시하는 것이 아니라, 디플로이먼트처럼 레플리카셋을 포함하는 오브젝트의 생성을 감시한다.
- 이외:
  - 데몬셋
  - 컨피그맵
  - 레플리카셋
  - PV
  - PVC
  - 스테이트풀셋

## 레플리카셋으로 파드 수 관리하기

- 다수의 파드를 만드는 오브젝트
- 파드 수를 보장하는 기능만 제공한다.

### 실습

1. 배포된 파드의 상태 확인
   ```bash
    kubectl get pods
   ```
2. nginx-pod scale 명령어로 3개 늘리기
   ```bash
    kubectl scale pod nginx-pod --replicas=3
    > ERROR!
   ```
   - 리소스를 찾을 수 없다는 에러 메시지 발생.
   - nginx-pod는 파드로 생성됐기 때문에, 디플로이먼트 오브젝트에 속하지 않는다.
3. deployment를 활용해 3개로 늘리기
   ```bash
    kubectl scale deployment dpy-nginx --replicas=3
   ```

## 스펙을 지정해 오브젝트 생성하기

- `kubectl create deployment` 명령으로 디플로이먼트를 생성할 수 있지만, 한 개의 파드만 만들 수 있다.
- `create` 에서는 `replicas` 옵션을 사용할 수 없다.
- `scale`은 이미 만들어진 디플로이먼트에서만 사용할 수 있다.
- 이와 같은 설정을 동시에 하려면, 필요한 내용을 파일로 작성해야 한다. => **오브젝트 스펙(spec)**

```yaml
# echo-hname.yaml
apiVersion: apps/v1 # API의 버전
kind: Deployment # 오브젝트의 종류
metadata:
  name: echo-hname # 디플로이먼트의 이름
  labels: # 디플로이먼트의 레이블
    app: nginx
spec:
  replicas: 3 # 몇 개의 파드를 생성할지 결정
  # 셀렉터의 레이블 지정
  selector: 
    matchLabels:
      app: nginx
  # 템플릿의 레이블 지정
  template:
    metadata:
      labels:
        app: nginx
    # 템플릿에서 사용할 컨테이너 이미지 지정
    spec:
      containers:
      - name: echo-hname
        image: sysnet4admin/echo-hname # 사용되는 이미지
```
```yaml
# nginx-pod.yaml
apiVersions: v1
kind: Pod
metadata:
  # 파드의 이름
  name: nginx-pod
spec:
  # 파드에서 호출할 컨테이너 이미지 지정
  container:
  - name: container-name
    image: nginx
```

- 사용가능한 API 버전 확인
  ```bash
    kubectl api-versions
  ```
- 쿠버네티스는 API 버전마다 포함되는 오브젝트(kind)와 내용이 다르다.

### 실습

1. echo-hname.yaml 파일을 이용해 디플로이먼트 생성
  ```bash
    kubectl create -f ~/_Book_k8sInfra/ch3/3.2.4/echo-hname.yaml
  ```
2. 새로 생성된 echo-hname의 파드 개수 확인
  ```bash
    kubectl get pods
  ```
3. echo-hname.yaml 수정
  ```bash
    sed -i 's/replicas: 3/replicas: 6/' ~/_Book_k8sInfra/ch3/3.2.4/echo-hname.yaml
    # sed : streamlined editor
    # -i : --in-place의 약어. 변경 내용을 현재 파일에 바로 적용
    # s/ : 주어진 패턴을 원하는 패턴으로 변경
    cat ~/_Book_k8sInfra/ch3/3.2.4/echo-hname.yaml | grep replicas
    # 제대로 변경 되었는지 확인
  ```
4. 변경된 내용 적용
  ```bash
    kubectl create -f ~/_Book_k8sInfra/ch3/3.2.4/echo-hname.yaml
    # ERROR!
  ```
  - echo-hname이 이미 존재한다는 에러 메시지가 나온다.
  - 배포된 오브젝트의 스펙을 변경하려면 create를 사용해서는 안된다.

## apply로 오브젝트 생성하고 관리하기

### 실습
1. `kubectl apply`를 사용해 적용하기
   ```bash
    kubectl apply -f ~/_Book_k8sInfra/ch3/3.2.4/echo-hname.yaml
   ```
2. 변경된 개수만큼 pod가 늘어났는지 확인
   ```bash
    kubectl get pod
   ```
   - 변경 사항이 발생할 가능성이 있는 오브젝트는 처음부터 apply로 생성하는 것이 좋다.

## 파드의 컨테이너 자동 복구 방법
- 쿠버네티스는 거의 모든 부분이 자동 복구(셀프 힐링, Self-Healing)되도록 설계되었다.

### 실습

1. 파드에 접속하기 위해 파드의 IP를 얻어낸다.
   ```bash
    kubectl get pods -o wide
   ```
2. `kubectl exec` 명령어를 실행해 파드 컨테이너의 셸에 접속한다.
   ```bash
    kubectl exec -it nginx-pod -- /bin/bash
    # exec : execute를 의미
    # i : stdin
    # t : tty(teletypewriter)
    # it : 표준 입력을 명령줄 인터페이스로 작성한다는 의미
   ```
3. 실행중인 nginx의 PID를 확인한다.
   ```bash
    cat /run/nginx.pid
   ```
4. `ls -l` 명령으로 프로세스가 생성된 시간을 확인한다.
   ```bash
    ls -l /run/nginx.pid
   ```
5. m-k8s 터미널 하나를 더 띄워, 웹페이지를 1초에 한번 요청하도록 한다.
   ```bash
    i=1; while true; do sleep 1; echo $((i++)) `curl --silent {pod ip} | grep title` ; done
   ```
6. nginx의 프로세서인 PID 1번을 kill로 종료한다.
   ```
    kill 1
   ```
7. nginx 웹 페이지가 복구된 것을 확인한 후, nginx-pod에 접속한 후, nginx.pid가 생성된 시간으로 새로 생성된 프로세스인지 확인한다.

## 파드의 동작 보증 기능
