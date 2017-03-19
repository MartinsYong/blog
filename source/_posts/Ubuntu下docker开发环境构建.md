---
title: Ubuntu下docker开发环境构建
date: 2017-03-19 18:17:52
categories: 技术
tags: linux
---

系统版本:**16.04**

docker版本：**17.03.0-ce**（本文撰写时）

---

### 引入安装repository

- 安装以下包来令repository支持https协议（一般来说系统自带）
```
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
```

<!--more-->

- 添加官方GPG秘钥
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

- 建立stable版本repository
```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
```
### 安装

- 安装docker本体
```bash
sudo apt-get install docker-ce
```

- 看看是否安装成功
```bash
sudo docker --version
sudo docker info
```

### 权限问题

安装之后你会发现使用docker总是要sudo，不然就会出现permission denyed的问题

解决：

- 新增docker用户组
```bash
sudo groupadd docker
```

- 将当前用户加入docker用户组
```bash
sudo usermod -aG docker $USER
```

- 注销当前用户再重新登录之后就可以不用```sudo```来使用docker


### 网络问题

进行完以上操作后，可以尝试
```bash
docker pull ubuntu
```
如果没有网络超时的话，可以忽略以下操作

- 寻找加速器（阿里云、daocloud、网易蜂巢、时速云等）并注册获取加速器地址

- 载入docker repository地址
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["$(你的加速地址)"]
}
EOF
```

- 重启docker服务
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

enjoy!