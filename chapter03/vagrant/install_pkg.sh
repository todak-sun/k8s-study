#!/usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y # git 설치

# install docker 
yum install docker -y && systemctl enable --now docker # 도커 설치 및 구동

# install kubernetes cluster 
yum install kubectl-$1 kubelet-$1 kubeadm-$1 -y # 쿠버네티스를 구성하기 위해 첫 번째 변수로 넘겨받은 버전의 kubectl, kubelet, kubeadm을 설치하고 시작
systemctl enable --now kubelet

# git clone _Book_k8sInfra.git 
# 본 조건문을 통해, Main이란 글자가 넘어 왔을 때만, 코드를 실행할 수 있는 git 레포지토리를 클론함.
if [ $2 = 'Main' ]; then
  git clone https://github.com/sysnet4admin/_Book_k8sInfra.git
  mv /home/vagrant/_Book_k8sInfra $HOME
  find $HOME/_Book_k8sInfra/ -regex ".*\.\(sh\)" -exec chmod 700 {} \;
fi
