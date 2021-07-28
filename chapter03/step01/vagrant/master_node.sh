#!/usr/bin/env bash

# init kubernetes 
# kubeadm을 통해 쿠버네티스의 워커 노드를 받아들일 준비를 한다.
# 먼저, 토큰을 123456.1234567890123456로 지정하고, ttl(time to live)을 0으로 설정해서 기본값인 24시간 후에 토큰이 계속 유지되게 한다.
# 그리고 워커 노드가 정해진 토큰으로 들어오게 한다.
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10 

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
kubectl apply -f \
https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/172.16_net_calico.yaml