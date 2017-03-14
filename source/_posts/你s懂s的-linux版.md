---
title: 你s懂s的(linux版)
date: 2017-03-14 12:32:34
categories: 技术
tags: linux
---

## 反正就是你懂的嘛

### 本文环境

-ubuntu 16.04

### 安装

- 更新源
```bash
sudo add-apt-repository ppa:hzwhuang/ss-qt5
sudo apt-get update
```
- 安装
```bash
sudo apt-get install shadowsocks-qt5
```

<!--more-->

### 应用启动并配置

- 启动
```bash
ss-qt5
```

- 配置

可引入*gui-config.json*，也可通过gui界面写入配置参数保存，记得勾选自动连接

### 系统代理配置

- 利用Python包管理工具pip安装genpac
```bash
pip install genpac
```
- 下载[gwflist](https://github.com/JinnLynn/GenPAC/blob/master/test/gfwlist.txt)

- 生成代理规则
```bash
genpac -p "SOCKS5 127.0.0.1:1080" --gfwlist-local=~/gfwlist.txt --update-gfwlist-local -o ~/autoproxy.pac
```
我把*gfwlist.txt*放在了user目录下，同样把规则文件*autoproxy.pac*输出到user目录下

- 启用系统代理

在网络设置里，选择自动代理，填写url为
```
file:///home/{user}/autoproxy.pac
```
并应用

- 测试

使用浏览器打开一下Google

### 关于终端的代理

进行了上面的操作后，可以打开终端
```bash
curl www.google.com.hk
```
毫无意外，应该是超时

#### 使用proxychains

- 先安装一下
```bash
git clone https://github.com/rofl0r/proxychains-ng.git
cd proxychains-ng
./configure
make && make install
```

- 修改配置文件
```bash
cp ./src/proxychains.conf /etc/proxychains.conf
vi /etc/proxychains.conf
```
将```socks4 127.0.0.1 9095```改为
```
socks5 127.0.0.1 1080
```

- 测试
做之前的测试
```bash
proxychains4 curl www.google.com.hk
```
没问题！！

### Reference

[Linux终端挂代理方法整理](http://www.jianshu.com/p/8e7d7f57bf59)
