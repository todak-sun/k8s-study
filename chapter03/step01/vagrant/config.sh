#!/usr/bin/env bash

# vim configuration 
echo 'alias vi=vim' >> /etc/profile #vi 호출해도, vim을 실행할 수 있도록 변경

# swapoff -a to disable swapping
swapoff -a # 쿠버네티스의 설치 요구 조건을 맞추기 위해, 스왑을 해제
# sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab # 시스템이 재시작 되더라도, 스왑되지 않도록 설정.

# kubernetes repo
gg_pkg="packages.cloud.google.com/yum/doc" # 쿠버네티스의 레포지터리 설정 경로가 너무 길어지지 않도록 변수 처리
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode => selinux가 제한적으로 사용되지 않도록 permissive 모드로 변경
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
# 브리지 네트워크를 통과하는 IPv4와 IPv6의 패킷을 iptables가 관리하게 설정.
# 파드의 통신을 iptables로 제어함. > 필요에 따라 IPVS 같은 방식으로도 구성할 수 있다.
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter 
# br_netfilter 커널 모듈을 사용해 브리지로 네트워크를 구성. 
# IP 마스커레이드(Masquerate)를 사용해 내부 네트워크와 외부 네트워크를 분리.
# IP 마스커레이드는 커널에서 제공하는 NAT(Network Address Translation) 기능.

# local small dns & vagrant cannot parse and delivery shell code.
# 쿠버네티스 안에서 노드 간 통신을 이름으로 할 수 있도록 각 노드의 호스트 이름과 IP를 /etc/hosts에 설정.
# 이때, 워커 노드는 Vagrantfile에서 넘겨받은 N 변수로 전달된 노드 수에 맞게 동적으로 생성된다.
echo "192.168.1.10 m-k8s" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done

# config DNS  
# 외부와 통신할 수 있게 DNS 서버를 지정.
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

