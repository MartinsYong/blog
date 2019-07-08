---
title: vagrant磁盘拓容
date: 2018-12-05 18:10:22
categories: 技术
tags: linux
---

下面将给大家讲述一下博主使用**vagrant**虚拟机多次发生的问题及其解决方案。

### 令人窒息

> 哇，怎么又跑崩了？No disk space left...

之前用得好好的，然后出现了这样一个错误

运行命令
```sh
$ df -h
```

发现硬盘使用率100%

<!--more-->

### 亡羊补牢

> 大哥不行啊，这个环境有很多重要的资料，你要重装？？？

**不行，不能重装**

vagrant默认建立的虚拟磁盘空间大小只有**10G**，有相当大的概率会出现磁盘不足的问题

#### 使用VBoxManage修改虚拟硬盘size

##### 具体流程：

- 找到该vm下的磁盘文件，记录其uuid
- 将vmdk格式磁盘转换为vdi格式
- 修改磁盘大小
- 转回vmdk格式，并记录其uuid
- 修改vbox文件（vm描述文件），将旧的uuid变更为新的uuid
- 删除多余的文件，重启vm并检查

**注意！转回vmdk时必须将名称改为其他的名称以防报错**

##### 详细命令：

查看uuid
```
$ VBoxManage showhdinfo "ubuntu-xenial-16.04-cloudimg.vmdk"
```

转换格式
```
$ VBoxManage clonehd "ubuntu-xenial-16.04-cloudimg.vmdk" "ubuntu-xenial-16.04-cloudimg.vdi" --format vdi
```

修改磁盘大小(50GB)
```
$ VBoxManage modifyhd "ubuntu-xenial-16.04-cloudimg.vdi" --resize 51200
```

### 未雨绸缪

在很多情况下，我们是可以预见到默认的10G磁盘不够用的。因此，我们可以在vagrant初始化时修改磁盘大小，消除隐患。

#### 使用vagrant-disksize插件

[具体repo](https://github.com/sprotheroe/vagrant-disksize)

安装方法：
```
$ vagrant plugin install vagrant-disksize
```

使用方法：
- `vagrant init xxx`后打开Vagrantfile
- 在中间添加`config.disksize.size = '50GB'`
- 启动vm