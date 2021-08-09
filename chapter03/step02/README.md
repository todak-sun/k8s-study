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

### 실습
1. 어떤 파드들이 있는지 확인
   ```bash  
    kubectl get pod
   ```
2. nginx-pod 삭제
   ```bash
    kubectl delete pod nginx-pod
   ```
3. echo-hname pod중 하나 삭제
   ```bash
    kubectl delete pod echo-hname-{hash}
   ```
4. 다시 pod 목록 확인
   - nginx-pod는 사라져 있다.
     - 디플로이먼트에 속하는 파드가 아니기에, 어떤 컨트롤러도 이 파드를 관리하지 않는다.
   - echo-hname의 경우, 삭제를 시도한 pod는 사라졌지만, pod의 총 개수는 이전과 같이 유지된다.
     - echo-hname은 디플로이먼트에 속한 파드이다.
     - replicas에서 6개로 선언했기에, 파드의 수를 항상 확인하고 부족하면 새로운 파드를 만들어낸다.
5. 디플로이먼트 삭제
   ```
    kubectl delete deployment echo-hanme
   ```

## 노드 자원 보호하기
- 노드의 목적: 노드는 쿠버네티스 스케줄러에서 파드를 할당받고 처리하는 역할을 한다.
- 문제가 생긴 노드에 파드를 할당하면, 문제가 생길 가능성이 높다.
- 하지만, 쿠버네티스는 모든 노드에 균등하게 파드를 할당하려고 한다.
  - 이럴 때 cordon이란 기능을 사용해 해결할 수 있다!

### 실습

1. 실습에 필요한 파드 생성
  ```bash
    kubectl apply -f echo-hname.yaml
  ```

2. scale 명령어로 파드를 9개로 늘리기
  ```bash
    kubectl scale deployment echo-hname --replicas=9
  ```

3. 배포된 9개의 파드를 확인하기.
  ```bash
    kubectl get pod -o=custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:spec.nodeName
  ```
 - 배포된 파드의 세부 값을 확인해보자
   1. 배포된 파드 중 하나를 -o yaml 옵션으로 확인
     ```bash
       kubectl get pod {pad-name} -o yaml > pod.yaml
     ```
   2. pod.yaml의 내용을 살펴보며 원하는 세부 값을 확인

4. scale의 파드의 수를 3개로 줄인다.
  ```bash
    kubectl scale deployment echo-hname --replicas=3
  ```

5. 더이상 배포를 원하지 않는 노드에 cordon 명령어 실행
  ```bash
    kubectl cordon {node-name}
  ```

6. 노드의 상태를 확인
  ```bash
    kubectl get nodes
  ```
  - 제대로 작동했다면, cordon이 적용된 노드에 SchedulingDisabled가 표시된다
   
7. 파드의 수를 늘려본다
   ```bash
    kubectl scale deployment echo-hname --replicas=9
   ```
  - 파드의 수가 9개로 늘어나지만, 위에서 cordon이 적용된 노드에는 배포되지 않는다.

8. uncordon 명령어를 사용해, 해제해본다
   ```bash
    kubectl uncordon {node-name}
   ```
   
## 노드 유지보수하기
- 노드의 커널을 업데이트하거나, 노드의 메모리를 증설하는 등의 작업이 필요해 노드를 꺼야할 때는 어떻게 해야할까?
- 이럴 경우를 대비해 쿠버네티스는 drain 기능을 제공한다.

### 실습
1. `kubectl drain` 명령으로 특정 노드를 파드가 없는 상태로 만든다.
   ```bash
    kubectl drain w3-k8s
    ---------------------------------------------------------------------
    error: unable to drain node "w3-k8s", aborting command...

    There are pending nodes to be drained:
    w3-k8s
    error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-system/calico-node-rgzbs, kube-system/kube-proxy-b2pwp
   ```
   - drain은 실제로 파드를 옮기는 것이 아니라, 노드에서 파드를 삭제하고 다른 곳에 다시 생성한다.
   - 쿠버네티스에서 대부분 이동은 파드를 지우고 다시 만드는 과정을 의미한다.
   - 그러나, DemonSet의 경우 각 노드에 1개만 존재하는 파드라서, drain으로는 삭제할 수 없다.

2. `drain` 명령어와 `ignore-demonsets` 옵션을 함께 사용
  ```bash
    kubectl drain w3-k8s --ignore-daemonsets
  ```
  - 본 옵션을 사용할 경우, 경고가 발생하지만 모든 파드가 이동된다.

3. 모든 파드가 이동되었는지 확인
  ```bash
    kubectl get pods -o=custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName
  ```
4. drain 명령이 수행된 노드의 상태 확인
  ```bash
    kubectl get nodes
  ```
  - `cordon` 명령어를 사용한 것과 같이, SchedulingDisabled 상태이다.

5. `uncordon` 명령어로 노드를 다시 사용가능한 상태로 복구

## 파드 업데이트하고 복구하기

- 파드 운영시, 업데이트 또는 이전 버전으로 복구를 해야하는 일이 빈번하게 발생한다.

### 실습 - 파드 업데이트

1. 다음 명령으로 컨테이너 버전 업데이트를 테스트하기 위한 파드를 배포한다.
   ```
    kubectl apply -f rollout-nginx.yaml --record
   ```
  - --record 는 매우 중요한 옵션으로, 배포한 정보의 히스토리를 기록한다.
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
      # deployment의 이름
    name: rollout-nginx
  spec:
      # 레플리카셋 생성 개수
    replicas: 3
      # 셀렉터의 레이블 지정
    selector:
      matchLabels:
        app: nginx
    template:
      # 템플릿의 레이블 지정
      metadata:
        labels:
          app: nginx
          # 템플릿에서 사용할 컨테이너 이미지 및 버전 지정
      spec:
        containers:
        - name: nginx
          image: nginx:1.15.12
  ```

2. `record` 옵션으로 기록된 히스토리 확인
   ```bash
    kubectl rollout history deployment/rollout-nginx
   ```
3. 배포한 파드의 정보 확인
   ```bash
    kubectl get pod -o wide
   ```
4. 배포된 파드에 속해 있는 nginx 컨테이너 버전 확인
   ```bash
    curl -I --silent {IP} | grep Server
   ```
5. `set image` 명령으로 파드의 nginx 컨테이너 버전을 1.16.0으로 업데이트 후, record로 기록
   ```bash
    kubectl set image deployment rollout-nginx nginx=nginx:1.16.0 --record
   ```
6. 업데이트 후 파드 상태 확인
   - 파드의 이름과 IP가 모두 변경 되었다.
   - 업데이트 기본 값은 전체의 1/4(25%) 개이며, 최소값은 1개
7. nginx 컨테이너가 1.16.0으로 모두 업데이트되면 Deployment의 상태를 확인
   ```bash
    kubectl rollout status deployment rollout-nginx
   ```
8. `rollout history` 명령으로 그간 적용된 명령들 확인
   ```bash
    kubectl rollout history deployment rollout-nginx
   ```
9. curl -I 명령으로 업데이트(1.16.0)이 제대로 이루어졌는지도 확인
   ```bash
    curl -I --silent {IP} | grep Server
   ```

### 실습 - 파드 복구

1. set image 명령으로 nginx 컨테이너 버전을 존재하지 않는 버전으로 세팅
   ```bash
    kubectl set image deployment rollout-nginx nginx=nginx:1.17.23 --record
   ```
   
2. 파드 상태 확인
   ```bash
    kubectl get pods -o=custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName
   ```
   - Pending 상태에서 넘어가지 않는다.
3. `rollout status` 명령어로 확인
   ```bash
    kubectl rollout status deployment rollout-nginx
   ```
4. `describe` 명령으로 문제 살피기
   ```bash
    kubectl describe deployment rollout-nginx
   ```
5. 정상 상태를 복구하기 위해 rollout history로 확인
   ```bash
    kubectl rollout history deployment rollout-nginx
   ```
6. `rollout undo`로 명령 실행을 취소해 마지막 단계(revision 3)에서 전 단계(rivision 2)로 상태 되돌리기
   ```bash
    kubectl rollout undo deployment rollout-nginx
   ```
7. rollout history로 실행된 명령을 확인
   ```bash
    kubectl rollout history deployment rollout-nginx
   ```
   - 현재 상태를 revision 2로 되돌렸기 때문에, revision 2는 삭제되고, 가장 최근 상태는 revision 4가 된다.