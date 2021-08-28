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

## PV와 PVC

- 파드는 언제라도 생성되고 지워진다.
- 하지만, 파드에서 생성한 내용을 기록하고 보관하거나 모든 파드가 동일한 설정 값을 유지하고 관리하기 위해 공유된 볼륨으로부터 공통된 설정을 가지고 올 수 있도록 설계해야 할 때도 있다.
- 이를 위해, 쿠버네티스가 제공하는 볼륨은 아래와 같이 다양하다.
  - 임시: emptyDir
  - 로컬: host Path, local
  - 원격: persistentVolumeClaim, cephfs, cinder, csi, fc(fibre channel), flexVolume, flocker, glusterefs, iscsi, nfs, portworxVolume, quobyte, rbd, scaleIO, storageos, vsphereVolume
  - 특수 목적: downwardAPI, configMap, secret, azureFile, projected
  - 클라우드: awsElasticBlockStore, azureDisk, gcePersistentDisk

- 쿠버네티스는 필요할 때 PVC(PersistentVolumeClaim, 지속적으로 사용 가능한 볼륨 요청)를 요청해 사용한다.
- PVC를 사용하려면 PV(PersistentVolume, 지속적으로 사용 가능한 볼륨)로 볼륨을 선언해야 한다.
- PV는 볼륨을 사용할 수 있게 준비하는 단계, PVC는 준비된 볼륨에서 일정 공간을 할당받는 것이다.

### 실습 - NFS 볼륨에 PV/PVC 만들고 파드에 연결

1. 마스터 노드에 NFS 구성
  ```bash
    mkdir /nfs_shared
    echo '/nfs_shared 192.168.1.0/24(rw,sync,no_root_squash)' >> /etc/exports
  ```
2. NFS 서버 활성화 & 재시작시에도 자동적용
  ```bash
    systemctl enable --now nfs
  ```
3. PV 생성
  ```bash
    k apply -f ~/_Book_k8sInfra/ch3/3.4.3/nfs-pv.yaml
  ```
4. PV 상태확인
  ```bash
    k get pv
  ```
5. PVC 생성
  ```bash
    k apply -f ~/Book_k8sInfra/ch3/3.4.3/nfs-pvc.yaml
  ```
6. 생성된 PVC 확인
  ```bash
    k get pvc
  ```
7. PV의 상태 다시 확인
  ```bash
    k get pv
  ```
8. 생성한 PVC를 볼륨으로 사용하는 디플로이먼트 배포
  ```bash
    k apply -f ~/Book_k8sInfra/ch3/3.4.3/nfs-pvc-deploy.yaml
  ```
9. 생성된 파드 확인
  ```bash
    k get pods
  ```
