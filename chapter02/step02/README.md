# 가상머신에 필요한 설정 자동으로 구성

## VagrantFile 작성

```Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config| # 2는 베이그런트에서 루비로 코드를 읽어 실행할 때 작동하는 API 버전. do |config|는 베이그런트 설정의 시작을 알림
  config.vm.define "m-k8s" do |cfg|
    cfg.vm.box = "sysnet4admin/CentOS-k8s"
    cfg.vm.provider "virtualbox" do |vb|
      vb.name = "m-k8s(github_SysNet4Admin)"
      vb.cpus = 2
      vb.memory = 2048
      vb.customize ["modifyvm", :id, "--groups", "/k8s-SM(github_SysNet4Admin)"]
    end
    cfg.vm.host_name = "m-k8s"
    cfg.vm.network "private_network", ip: "192.168.1.10"
    cfg.vm.network "forwarded_port", guest: 22, host: 60010, auto_correct: true, id: "ssh"
    cfg.vm.synced_folder "../data", "/vagrant", disabled: true
  end
end
```

## 테스트

```shell
vagrant up

vagrant ssh

ip addr show eth1
```


## 가상 머신에 추가 패키지 설치하기

1. VagrantFile 작성
```VagrantFile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.define "m-k8s" do |cfg|
    cfg.vm.box = "sysnet4admin/CentOS-k8s"
    cfg.vm.provider "virtualbox" do |vb|
      vb.name = "m-k8s(github_SysNet4Admin)"
      vb.cpus = 2
      vb.memory = 2048
      vb.customize ["modifyvm", :id, "--groups", "/k8s-SM(github_SysNet4Admin)"]
    end
    cfg.vm.host_name = "m-k8s"
    cfg.vm.network "private_network", ip: "192.168.1.10"
    cfg.vm.network "forwarded_port", guest: 22, host: 60010, auto_correct: true, id: "ssh"
    cfg.vm.synced_folder "../data", "/vagrant", disabled: true
    cfg.vm.provision "shell", path: "install_pkg.sh" #add provisioning script
  end
end
```

2. install_pkg.sh 작성
```sh
#!/usr/bin/env bash
# install packages
yum install epel-release -y
yum install vim-enhanced -y
```

3. vagrant provision 실행
4. 테스트

```shell
vagrant ssh
yum repolist
vi .bashrc # 하이라이트 적용 되었는지 확인
exit
vagrant destroy -f
```

## 가상 머신 추가로 구성하기

1. Vagrantfile 작성
```Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.define "m-k8s" do |cfg|
    cfg.vm.box = "sysnet4admin/CentOS-k8s"
    cfg.vm.provider "virtualbox" do |vb|
      vb.name = "m-k8s(github_SysNet4Admin)"
      vb.cpus = 2
      vb.memory = 2048
      vb.customize ["modifyvm", :id, "--groups", "/k8s-SM(github_SysNet4Admin)"]
    end
    cfg.vm.host_name = "m-k8s"
    cfg.vm.network "private_network", ip: "192.168.1.10"
    cfg.vm.network "forwarded_port", guest: 22, host: 60010, auto_correct: true, id: "ssh"
    cfg.vm.synced_folder "../data", "/vagrant", disabled: true
    cfg.vm.provision "shell", path: "install_pkg.sh" #add provisioning script
    cfg.vm.provision "file", source: "ping_2_nds.sh", destination: "ping_2_nds.sh"
    cfg.vm.provision "shell", path: "config.sh"
  end
  #=============#
  # Added Nodes #
  #=============#

  (1..3).each do |i| # 1부터 3까지 3개의 인자를 반복해 i로 입력
    config.vm.define "w#{i}-k8s" do |cfg| # {i} 값이 1, 2, 3으로 차례대로 치환
      cfg.vm.box = "sysnet4admin/CentOS-k8s"
      cfg.vm.provider "virtualbox" do |vb|
        vb.name = "w#{i}-k8s(github_SysNet4Admin)" #{i} 값이 1, 2, 3으로 차례대로 치환
        vb.cpus = 1
        vb.memory = 1024 # 메모리는 1GB만 사용
        vb.customize ["modifyvm", :id, "--groups", "/k8s-SM(github_SysNet4Admin)"]
      end
      cfg.vm.host_name = "w#{i}-k8s" #{i} 값이 1, 2, 3으로 차례대로 치환
      cfg.vm.network "private_network", ip: "192.168.1.10#{i}" #{i} 값이 1, 2, 3으로 차례대로 치환
      cfg.vm.network "forwarded_port", guest: 22, host: "6010#{i}", auto_correct: true, id: "ssh" #{i} 값이 1, 2, 3으로 차례대로 치환
      cfg.vm.synced_folder "../data", "/vagrant", disabled: true
      cfg.vm.provision "shell", path: "install_pkg.sh"
    end
  end
end
```

2. install_pkg.sh 작성
```shell
#!/usr/bin/env bash
# install packages
yum install epel-release -y
yum install vim-enhanced -y
```
3. ping_2_nds.sh 작성

```shell
# ping 3 times per nodes
ping 192.168.1.101 -c 3
ping 192.168.1.102 -c 3
ping 192.168.1.103 -c 3
```

4. 권한 변경용 스크립트 작성(config.sh)

```shell
#!/usr/bin/env bash
# modify permission
chmod 744 ./ping_2_nds.sh
```

5. 확인

```
vagrant ssh m-k8s
./ping_2_nds.sh
exit

```


## putty & super putty 설치
https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
https://github.com/jimradford/superputty/releases

### 접속 정보 슈퍼푸티에 구성하기

- 오른쪽 화면 > Sessions > PuTTY Sessions 오른쪽 클릭 > New Folder > k8s
- k8s 폴더 오른쪽 클릭 -> New
- 설정
  - Session Name: m-k8s
  - Host Name: 127.0.0.1
  - TCP Port: 60010
  - Login Username: root
  - Extra PuTTY Arguments: -pw vagrant
- 위의 설정 그대로 복사해서 아래만 바꿔줌
  - Session Name: w1-k8s, w1-, w2-
  - TCP Port: 60101, 60102, 60103
- 평문 접속을 위한 슈퍼푸티의 보안 설정 변경
  - Tools > Options
  - GUI tab 이동
  - Security > Allow plain text 체크
- k8s 폴더 오른쪽 클릭 > connect all
- 적절히 보기 좋게 화면 배치 후, 위쪽 command 창에 hostname

