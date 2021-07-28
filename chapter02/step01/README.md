# 실습 준비

## 버추얼 박스 설치
https://www.virtualbox.org/wiki/Downloads

## 베이그런트 설치
https://www.vagrantup.com/

## 사전 체크
- 프로비저닝을 위한 코드 작성
- 베이그란트에서 위의 코드를 불러옴
- 버추얼박스에 운영 체제 설치

### vagrant 명령어
- vagrant init: 프로비전을 위한 기초 파일 생성
- vagrant upL Vagrantfile을 읽어 들여 프로비저닝을 진행
- vagrant halt: 베이그란트에서 다루는 가상 머신을 종료
- vagrant destroy: 베이그란트에서 관리하는 가상 머신을 삭제
- vagrant ssh: 베이그란트에서 관리하는 가상 머신에 ssh로 접속
- vagrant provision: 베이그란트에서 관리하는 가상 머신에 변경된 설정을 저굥

1. vagrant 기초 파일 생성
  ```shell
    # 설치폴더 이동 후
    vagrant init
  ```
2. Vagrantfile 에서 config.vm.box = "base"라는 내용이 있는지 확인

3. 아무것도 변경하지 않은 채 파일을 닫고 명령 프롬프트에서 vagrant up을 바로 실행
  ```log
  Bringing machine 'default' up with 'virtualbox' provider...
  ==> default: Box 'base' could not be found. Attempting to find and install...
      default: Box Provider: virtualbox
      default: Box Version: >= 0       
  ==> default: Box file was not detected as metadata. Adding it directly...
  ==> default: Adding box 'base' (v0) for provider: virtualbox
      default: Downloading: base
      default: 
  An error occurred while downloading the remote file. The error
  message, if any, is reproduced below. Please fix this error and try
  again.

  Couldn't open file D:/workspace/github/k8s-study/vagrant/base
  ```
  => 설치하려는 이미지가 'base'로 명시되어 있으나, 해당 이미지를 찾지 못해 발생하는 에러.

4. 실습에 필요한 구성이 갖춰진 이미지 사용
   https://app.vagrantup.com/sysnet4admin/boxes/CentOS-k8s

5. 다시 한 번 vagrant up

6. 버츄얼 박스 구동 후, 가상 머신이 제대로 생성되었는 지 확인

7. Vagrantfile이 있는 경로에서 vagrant ssh

8. 정상 설치 확인

```shell
vagrant ssh
uptime
cat /etc/redhat-release
```

9. 가상 머신 종료 및 삭제
    
```shell
vagrant destroy -f
```