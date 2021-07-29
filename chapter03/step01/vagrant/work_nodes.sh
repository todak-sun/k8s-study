#!/usr/bin/env bash

# kubeadm을 이용해 쿠버네티스 마스터 노드에 접속한다.
# 이때 필요한 토큰은 기존에 마스터 노드에서 생성한 것과 같다.

# 간단하게 구성하기 위해 --discovery-token~로 인증을 무시하고, 
# API 서버 주소인 192.168.1.10으로 기본 포트 6443번 포트에 접속하도록 설정한다.

# config for work_nodes only 
kubeadm join --token 123456.1234567890123456 \
             --discovery-token-unsafe-skip-ca-verification 192.168.1.10:6443