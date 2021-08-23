#!/usr/bin/env bash

# init kubernetes 
# kubeadm을 통해 쿠버네티스의 워커 노드를 받아들일 준비를 한다.
# 먼저, 토큰을 123456.1234567890123456로 지정하고, ttl(time to live)을 0으로 설정해서 기본값인 24시간 후에 토큰이 계속 유지되게 한다.
# 그리고 워커 노드가 정해진 토큰으로 들어오게 한다.
# 쿠버네티스가 자동으로 컨테이너에 부여하는 네트워크를 172.16.0.0/16으로 제공하고
# 워커노드가 접속하는 API 서버의 IP를 192.168.1.10으로 지정해 워커 노드들이 자동으로 API 서버에 연결되게 한다.
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10 

# config for master node only 
# 마스터 노드에서 현재 사용자가 쿠버네티스를 정상 구동 할 수 있게
# 설정 파일을 루트의 홈 디렉토리에 복사하고 쿠버네티스를 이용할 사용자에게 권한을 부여.
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
# CNI(Container Network Interface)인 캘리코의 설정을 적용해 쿠버네티스의 네트워크를 구성한다.
kubectl apply -f \
https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/172.16_net_calico.yaml