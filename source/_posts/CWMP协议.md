---
title: CWMP协议
date: 2018-10-06 19:25:11
categories: 技术
tags: 通信
---

## 关于cwmp

全称：CPE WAN Management Protocol，用于管理CPE。采用http协议进行通讯，消息格式为XML Soap。

消息数据模型及例子参考：[cwmp](https://cwmp-data-models.broadband-forum.org/)

下面开始介绍一下好用的基于CWMP协议的客户端和服务端。

<!--more-->

## easycwmp

> cwmp client for openwrt

#### 项目地址

> [easycwmp](http://www.easycwmp.org/ "easycwmp")

安装步骤都在以上链接中

#### 配置参数

```conf
config local
		# 网络接口，用于获取设备网络IP地址用于服务器访问(connection request)（在公司改版的easycwmp已可以自动获取本参数，因此可以不填）
        option interface 'br-lan'
		#cpe设备开启的http服务端口（必须设置）
        option port '7547'
		#ubus的socket路径（必须设置）
        option ubus_socket '/var/run/ubus.sock'
        option date_format '%FT%T%z'
		#服务器访问cpe设备(connection request)http服务认证信息
        option username 'username'
        option password 'password'
		#输出日志的级别
        option logging_level '3'

config acs
		#服务器地址
        option url 'https://example.mt:8081/openacs/acs'
		#是否开启ssl证书验证（验证CA是否合法）
        option ssl_verify 'enabled'
		#客户端ssl证书（其实不用填）
        option ssl_cert '/etc/ssl/certs/cert.pem'
        option ssl_cacert '/etc/ssl/certs/cert.pem'
		#服务器请求认证信息
        option username 'acs'
        option password 'acs'
		#inform设置（tr069协议的一部分，定时发送inform信息到服务器）
        option periodic_enable '1'
        option periodic_interval '300'
        option periodic_time '0001-01-01T00:00:00Z'
```

#### 关于HTTPS（SSL）

easycwmp涉及到的ssl设置参数只有三个，其中**ssl_verify**十分重要。

1. 如果开启了**ssl_verify**，此软件将会对服务器的SSL证书进行验证，此时应该将服务器的CA证书(不管是合法还是非法)放在*/etc/ssl/certs*下，不然可能无法正常访问。
2. 其他两个参数分别是服务器给客户端的证书(包含CA证书)。其实还缺一个参数，那就是生成SSL证书的key，笔者觉得是软件的缺陷（具体可查看源码和*libcurl*库API）。

#### 使用与测试

easycwmp在openwrt系统下正常安装后，会自动注册为openwrt系统的标准守护进程，并且也有ubus事件可被调用。

```shell
/etc/init.d/easycwmpd start
/etc/init.d/easycwmpd stop
/etc/init.d/easycwmpd restart
```

以上是*easycwmpd*（即easycwmp守护进程简单的开启和关闭命令）。而在测试的情况下，我们可以直接使用`easycwmpd -f`进行前台测试。**注意：**编译easycwmp时候须打开devel和debug选项，前台测试时终端才会有日志输出。

另外，easycwmp还带一个可用程序，可执行文件是*easycwmp*。此执行文件其实是由一系列脚本构成，这些脚本的路径一般在*/usr/share/easycwmp/functions*下。这些脚本的业务包括：注册设备参数、获取设备参数和设置对应的设备参数。通过执行命令`easycwmp get`，我们可获取到此设备所有可通过cwmp协议获取到的信息。

#### easycwmp脚本示例

```sh
#!/bin/sh
# Copyright (C) 2016 MOHAMED Kallel <mohamed.kallel@yahoo.fr>

#common_execute_method_param "$parameter" "$permission" "$get_cmd" "$set_cmd" "xsd:$type" "$forcedinform"
#  $forcedinform should be set to 1 if the parameter is included in the inform message otherwise empty
#  Default of $type = string

#############################
#   Entry point functions   #
#############################

prefix_list="$prefix_list $DMROOT.WiFi."
entry_execute_method_list="$entry_execute_method_list entry_execute_method_root_WiFi"

entry_execute_method_root_WiFi() {
	case "$1" in ""|"$DMROOT."|"$DMROOT.WiFi."*)
		common_execute_method_obj "$DMROOT.WiFi." "0"
		common_execute_method_obj "$DMROOT.WiFi.Radio." "0" "" "" "wifi_radio_browse_instances $1"
		common_execute_method_obj "$DMROOT.WiFi.SSID." "1" "add_wifi_iface" "" "wifi_ssid_browse_instances $1"
		common_execute_method_obj "$DMROOT.WiFi.AccessPoint." "1" "add_wifi_iface" "" "wifi_ap_browse_instances $1"
		return 0
		;;
	esac
	return $E_INVALID_PARAMETER_NAME;
}

sub_entry_WiFi_Radio() {
	local j="$2"
	local radio="$3"
	case_param "$1" belongto "$DMROOT.WiFi.Radio.$j." && {
		common_execute_method_obj "$DMROOT.WiFi.Radio.$j." "0"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.Enable" "1" "wifi_radio_get_Enable $radio" "wifi_radio_set_Enable $radio" "xsd:boolean"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.Status" "0" "wifi_radio_get_Status $radio"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.Name" "0" "wifi_radio_get_Name $radio"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.SupportedFrequencyBands" "0" "wifi_radio_get_FrequencyBands $radio"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.OperatingFrequencyBand" "0" "wifi_radio_get_FrequencyBands $radio"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.ChannelsInUse" "0" "wifi_radio_get_ChannelsInUse $radio"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.Channel" "1" "wifi_radio_get_Channel $radio" "wifi_radio_set_Channel $radio" "xsd:unsignedInt"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.AutoChannelSupported" "0" "echo 1" "" "xsd:boolean"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.AutoChannelEnable" "1" "wifi_radio_get_AutoChannelEnable $radio" "wifi_radio_set_AutoChannelEnable $radio" "xsd:boolean"
		common_execute_method_param  "$DMROOT.WiFi.Radio.$j.OperatingStandards" "1" "wifi_radio_get_OperatingStandards $radio" "wifi_radio_set_OperatingStandards $radio"
		return 0
	}
	return $E_INVALID_PARAMETER_NAME;		
}

sub_entry_WiFi_SSID() {
	local j="$2"
	local iface="$3"
	case_param "$1" belongto "$DMROOT.WiFi.SSID.$j." && {
		common_execute_method_obj "$DMROOT.WiFi.SSID.$j." "1" "" "del_wifi_iface $iface"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.Enable" "1" "wifi_ssid_get_Enable $iface" "wifi_ssid_set_Enable $iface" "xsd:boolean"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.Status" "0" "wifi_ssid_get_Status $iface"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.Name" "0" "wifi_ssid_get_Name $iface"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.LowerLayers" "1" "wifi_ssid_get_LowerLayers $iface" "wifi_ssid_set_LowerLayers $iface"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.SSID" "1" "wifi_ssid_get_SSID $iface" "wifi_ssid_set_SSID $iface"
		common_execute_method_param  "$DMROOT.WiFi.SSID.$j.X_IPInterface" "1" "wifi_ssid_get_X_IPInterface $iface" "wifi_ssid_set_X_IPInterface $iface"
		return 0
	}
	return $E_INVALID_PARAMETER_NAME;		
}

sub_entry_WiFi_AccessPoint() {
	local j="$2"
	local iface="$3"
	case_param "$1" belongto "$DMROOT.WiFi.AccessPoint.$j." && {
		common_execute_method_obj "$DMROOT.WiFi.AccessPoint.$j." "1" "" "del_wifi_iface $iface"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Enable" "1" "wifi_ap_get_Enable $iface" "wifi_ap_set_Enable $iface" "xsd:boolean"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Status" "0" "wifi_ap_get_Status $iface"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.SSIDReference" "0" "echo $DMROOT.WiFi.SSID.$j."
		common_execute_method_obj "$DMROOT.WiFi.AccessPoint.$j.Security." "0"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Security.ModesSupported" "0" "wifi_ap_get_ModesSupported $iface"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Security.ModeEnabled" "1" "wifi_ap_get_ModeEnabled $iface" "wifi_ap_set_ModeEnabled $iface"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Security.WEPKey" "1" "wifi_get_secret" "wifi_ap_set_WEPKey $iface" "xsd:hexBinary­"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Security.PreSharedKey" "1" "wifi_get_secret" "wifi_ap_set_PreSharedKey $iface" "xsd:hexBinary­"
		common_execute_method_param  "$DMROOT.WiFi.AccessPoint.$j.Security.KeyPassphrase" "1" "wifi_get_secret" "wifi_ap_set_KeyPassphrase $iface"
		return 0
	}
	return $E_INVALID_PARAMETER_NAME;		
}

#############################
#   Model params functions   #
#############################

wifi_radio_get_max_instance() {
	local max=`$UCI_SHOW -X wireless | grep "wifi_radio_instance" | cut -d'=' -f2 | sed 's/[^0-9]*//g' | sort -nru | head -1`
	echo ${max:-0}
}

wifi_iface_get_max_instance() {
	local max=`$UCI_SHOW -X wireless | grep "wifi_iface_instance" | cut -d'=' -f2 | sed 's/[^0-9]*//g' | sort -nru | head -1`
	echo ${max:-0}
}

wifi_radio_update_instance() {
	local radio="$1"
	local instance=`$UCI_GET $radio.wifi_radio_instance`
	if [ -z "$instance" ]; then
		instance=`wifi_radio_get_max_instance`
		$UCI_SET $radio.wifi_radio_instance=$((++instance))
		$UCI_COMMIT
	fi
	echo $instance
}

wifi_iface_update_instance() {
	local iface="$1"
	local instance=`$UCI_GET $iface.wifi_iface_instance`
	if [ -z "$instance" ]; then
		instance=`wifi_iface_get_max_instance`
		$UCI_SET $iface.wifi_iface_instance=$((++instance))
		$UCI_COMMIT
	fi
	echo $instance
}

wifi_radio_browse_instances() {
	local radio radios=`$UCI_SHOW -X wireless | grep "wireless\..*=wifi-device" | cut -d "=" -f 1`
	for radio in $radios; do
		local j=`wifi_radio_update_instance $radio`
		sub_entry_WiFi_Radio  "$1" "$j" "$radio"
	done
}

wifi_ssid_browse_instances() {
	local iface ifaces=`$UCI_SHOW -X wireless | grep "wireless\..*=wifi-iface" | cut -d "=" -f 1`
	for iface in $ifaces; do
		local j=`wifi_iface_update_instance $iface`
		sub_entry_WiFi_SSID  "$1" "$j" "$iface"
	done
}

wifi_ap_browse_instances() {
	local iface ifaces=`$UCI_SHOW -X wireless | grep "wireless\..*=wifi-iface" | cut -d "=" -f 1`
	for iface in $ifaces; do
		local j=`wifi_iface_update_instance $iface`
		sub_entry_WiFi_AccessPoint  "$1" "$j" "$iface"
	done
}

add_wifi_iface() {
	local instance=`wifi_iface_get_max_instance`
	local section=`$UCI_ADD  wireless wifi-iface`
	$UCI_SET wireless.$section.wifi_iface_instance=$((++instance))
	$UCI_COMMIT
	echo $instance
}

del_wifi_iface() {
	local iface="$1"
	$UCI_DELETE $iface
	$UCI_COMMIT
	return 0
}

wifi_radio_get_Enable() {
	local val=`$UCI_GET $1.disabled`
	[ "$val" = "1" ] && echo "0" || echo "1"
}

wifi_radio_set_Enable() {
	local ret
	common_set_bool "$1.disabled" "$2" "" "1"
	ret=$?
	return $ret
}

wifi_radio_get_Status() {
	local device=${1#*.}
	local res up

	res=`ubus call network.wireless status`
	if [ "$res" != "" ]; then
		json_init
		json_load "$res" >&2
		json_select "$device" >&2
		json_get_var up up >&2
	fi
	[ "$up" = "1" ] && echo Up || echo Down
}

wifi_radio_get_Name() {
	echo ${1#*.}
}

wifi_radio_get_FrequencyBands() {
	local phy="phy${1#*radio}"
	local freq=`iw phy $phy info | grep  "MHz.*dBm" | head -1 | awk '{print $2}'`
	[ "${freq#24}" = "$freq" ] && echo "5GHz" || echo "2.4GHz"
}

wifi_radio_get_ChannelsInUse() {
	local freq="`iw phy phy0 info | grep  MHz.*dBm | awk -F'[][]' '{print $2}' |  tr '\n' ','`"
	echo ${freq%,}
}

wifi_radio_get_Channel() {
	local channel phy freq

	channel=`$UCI_GET $1.channel`
	[ "$channel" != "" -a "$channel" != "auto" ] && { echo $channel; return; }

	phy="phy${1#*radio}"
	freq=`iw phy $phy info | grep  "MHz.*dBm" | head -1 | awk '{print $2}'`
	if [ "${freq#24}" != "$freq" ]; then 
		channel=`iw dev | grep "channel.*(24.*MHz)" | head -1 | awk '{print $2}'`
	else
		channel=`iw dev | grep "channel" | grep -v "channel.*(24.*MHz)" | head -1 | awk '{print $2}'`		
	fi
	echo $channel
}

wifi_radio_set_Channel() {
	$UCI_SET $1.channel=$2
}

wifi_radio_get_AutoChannelEnable() {
	local en=`$UCI_GET $1.channel`
	[ "$en" = "" -o "$en" = "auto" ] && echo 1 || echo 0
}

wifi_radio_set_AutoChannelEnable() {
	local val=`echo "$2" | tr '[A-Z]' '[a-z]'`
	if [ "$val" = "1" -o "$val" = "true" ]; then
		$UCI_SET $1.channel=auto
	else
		local channel=`wifi_radio_get_Channel $1`
		$UCI_SET $1.channel=$channel
	fi	
}

wifi_radio_get_OperatingStandards() {
	local val=`$UCI_GET $1.hwmode`
	echo ${val#11}
}

wifi_radio_set_OperatingStandards() {
	$UCI_SET $1.hwmode=11$2
}

wifi_ssid_get_Enable() {
	local val=`$UCI_GET $1.disabled`
	[ "$val" = "1" ] && echo "0" || echo "1"
}

wifi_ssid_set_Enable() {
	local ret
	common_set_bool "$1.disabled" "$2" "" "1"
	ret=$?
	return $ret
}

wifi_ssid_get_Status() {
	local name=`wifi_ssid_get_Name $1`
	[ "$name" != "" ] && echo Up || echo Down
}

wifi_ssid_get_Name() {
	local iface=$1
	local res ifname section device e i=0

	device=`$UCI_GET $1.device`
	[ "$device" = "" ] && return 0
	res=`ubus call network.wireless status`
	[ "$res" = "" ] && return 0
	json_init
	json_load "$res"
	json_select "$device"
	json_select "interfaces"
	while [ 1 ]; do
		let i++
		json_select "$i"  >&2
		e=$?
		[ "$e" != 0 ] && break
		json_get_var section section >&2
		[ "$section" != "${iface#*.}" ] && { json_select ".." >&2; continue; }
		json_get_var ifname ifname >&2
		echo $ifname
		break;
	done
}

wifi_ssid_get_LowerLayers() {
	local device=`$UCI_GET $1.device`
	local instance=`$UCI_GET wireless.$device.wifi_radio_instance`
	[ "$instance" != "" ] && echo "$DMROOT.WiFi.Radio.$instance."
}

wifi_ssid_set_LowerLayers() {
	local tmp=${2#$DMROOT.WiFi.Radio.}
	[ "$tmp" = "$2" ] && return
	local instance=${tmp%.}
	[ "$tmp" = "$instance" ] && return
	local device=`$UCI_SHOW -X wireless | grep "wifi_radio_instance=$instance" | cut -d'.' -f2`
	$UCI_SET $1.device=$device
}

wifi_ssid_get_SSID() {
	local ssid=`$UCI_GET $1.ssid`
	echo $ssid
}

wifi_ssid_set_SSID() {
	$UCI_SET $1.ssid=$2
}

wifi_ssid_get_X_IPInterface() {
	local network=`$UCI_GET $1.network`
	local instance=`$UCI_GET network.$network.ip_int_instance`
	[ "$instance" != "" ] && echo "$DMROOT.IP.Interface.$instance."
}

wifi_ssid_set_X_IPInterface() {
	local tmp=${2#$DMROOT.IP.Interface.}
	[ "$tmp" = "$2" ] && return
	local instance=${tmp%.}
	[ "$tmp" = "$instance" ] && return
	local network=`$UCI_SHOW -X network | grep "ip_int_instance=$instance" | cut -d'.' -f2`
	$UCI_SET $1.network=$network
}

wifi_ap_get_Enable() {
	local val=`$UCI_GET $1.disabled`
	[ "$val" = "1" ] && echo "0" || echo "1"
}

wifi_ap_set_Enable() {
	local ret
	common_set_bool "$1.disabled" "$2" "" "1"
	ret=$?
	return $ret
}

wifi_ap_get_Status() {
	local name=`wifi_ssid_get_Name $1`
	[ "$name" != "" ] && echo Enabled || echo Disabled
}

wifi_ap_get_ModesSupported() {
	echo "None,WEP-64,WEP-128,WPA-Personal,WPA2-Personal,WPA-WPA2-Personal,WPA-Enterprise,WPA2-Enterprise,WPA-WPA2-Enterprise"
}

wifi_ap_get_ModeEnabled() {
	local key
	local encryption=`$UCI_GET $1.encryption`
	
	case "$encryption" in
		"psk2"*)
			echo "WPA2-Personal"
			;;
		"psk-mixed"*)
			echo "WPA-WPA2-Personal"
			;;
		"psk"*)
			echo "WPA-Personal"
			;;
		"wpa2"*)
			echo "WPA2-Enterprise"
			;;
		"wpa-mixed"*)
			echo "WPA-WPA2-Enterprise"
			;;
		"wpa"*)
			echo "WPA-Enterprise"
			;;
		"wep"*)
			key=`$UCI_GET $1.key`
			[ "$key" = "1" -o "$key" = "2" -o "$key" = "3" -o "$key" = "4" ] && key=`$UCI_GET $1.key$key`
			[ ${#key} = "26" ] && echo "WEP-128" || echo "WEP-64"
			;;
		*)
			echo "None"
			;;
	esac
}

wifi_ap_set_ModeEnabled() {
	local key
	local encryption=`wifi_ap_get_ModeEnabled $1`
	[ "$encryption" = "$2" ] && return 0
	
	case "$2" in
		"WPA2-Personal")
			$UCI_SET $1.encryption="psk2"
			;;
		"WPA-WPA2-Personal")
			$UCI_SET $1.encryption="psk-mixed"
			;;
		"WPA-Personal")
			$UCI_SET $1.encryption="psk"
			;;
		"WPA2-Enterprise")
			$UCI_SET $1.encryption="wpa2"
			;;
		"WPA-WPA2-Enterprise")
			$UCI_SET $1.encryption="wpa-mixed"
			;;
		"WPA-Enterprise")
			$UCI_SET $1.encryption="wpa"
			;;
		"WEP-64")
			$UCI_SET $1.encryption=wep
			$UCI_SET $1.key=1
			$UCI_SET $1.key1="0123456789012"
			;;
		"WEP-128")
			$UCI_SET $1.encryption=wep
			$UCI_SET $1.key=1
			$UCI_SET $1.key1="01234567890123456789012345"
			;;
		"None")
			$UCI_SET $1.encryption=
			$UCI_SET $1.key=
			;;
	esac
	return 0
}

wifi_get_secret() {
	return 0
}

wifi_ap_set_WEPKey() {
	$UCI_SET $1.key=1
	$UCI_SET $1.key1=$2
	return 0
}

wifi_ap_set_PreSharedKey() {
	$UCI_SET $1.key=$2
	return 0
}

wifi_ap_set_KeyPassphrase() {
	$UCI_SET $1.key=$2
	return 0
}

```

## genieacs

> cwmp auto configuration server

#### 项目地址

> [genieacs](https://github.com/genieacs/genieacs "genieacs")

#### 全部配置参数(来自lib/config.coffee)

```
  #默认配置文件目录
  CONFIG_DIR : {type : 'path', default : 'config'},
  #MongoDB完整地址，默认端口为27017
  MONGODB_CONNECTION_URL : {type : 'string', default : 'mongodb://127.0.0.1/genieacs'},
  #redis参数
  REDIS_PORT : {type : 'int', default : 6379},
  REDIS_HOST : {type : 'string', default : ''},
  REDIS_DB : {type : 'int', default : 0},
  #cwmp服务参数
  CWMP_WORKER_PROCESSES : {type : 'int', default : 0},
  CWMP_PORT : {type : 'int', default : 7547},
  CWMP_INTERFACE : {type : 'string', default : '0.0.0.0'},
  CWMP_SSL : {type : 'bool', default : false},
  CWMP_LOG_FILE : {type: 'path', default : ''},
  CWMP_ACCESS_LOG_FILE : {type : 'path', default : ''},
  #NBI(API)服务参数
  NBI_WORKER_PROCESSES : {type : 'int', default : 0},
  NBI_PORT : {type : 'int', default : 7557},
  NBI_INTERFACE : {type : 'string', default : '0.0.0.0'},
  NBI_SSL : {type : 'bool', default : false},
  NBI_LOG_FILE : {type: 'path', default : ''},
  NBI_ACCESS_LOG_FILE : {type : 'path', default : ''},
  #FS(静态文件服务)服务参数
  FS_WORKER_PROCESSES : {type : 'int', default : 0},
  FS_PORT : {type : 'int', default : 7567},
  FS_INTERFACE : {type : 'string', default : '0.0.0.0'},
  FS_SSL : {type : 'bool', default : false},
  FS_HOSTNAME : {type : 'string', default : 'acs.example.com'},
  FS_LOG_FILE : {type: 'path', default : ''},
  FS_ACCESS_LOG_FILE : {type : 'path', default : ''},

  UDP_CONNECTION_REQUEST_PORT : {type : 'int', default : 0},

  DOWNLOAD_TIMEOUT: {type : 'int', default : 3600},
  EXT_TIMEOUT: {type: 'int', default: 3000},
  MAX_CACHE_TTL : {type : 'int', default : 86400},
  DEBUG : {type : 'bool', default : false},
  RETRY_DELAY : {type : 'int', default : 300},
  SESSION_TIMEOUT : {type : 'int', default : 30},
  CONNECTION_REQUEST_TIMEOUT : {type : 'int', default: 2000},
  GPN_NEXT_LEVEL : {type : 'int', default : 0},
  GPV_BATCH_SIZE : {type : 'int', default : 32},
  MAX_DEPTH : {type: 'int', default : 16},
  COOKIES_PATH : {type : 'string'},
  LOG_FORMAT : {type : 'string', default : 'simple'},
  ACCESS_LOG_FORMAT : {type : 'string', default : ''},
  MAX_CONCURRENT_REQUESTS : {type : 'int', default: 20},
  DATETIME_MILLISECONDS : {type: 'bool', default: true},
  BOOLEAN_LITERAL : {type: 'bool', default: true},
  CONNECTION_REQUEST_ALLOW_BASIC_AUTH: {type: 'bool', default: false},
  MAX_COMMIT_ITERATIONS : {type : 'int', default: 32},

  # XML configuration
  XML_RECOVER : {type : 'bool', default : false},
  XML_IGNORE_ENC : {type : 'bool', default : false},
  XML_FORMAT : {type : 'bool', default : false},
  XML_NO_DECL : {type : 'bool', default : false},
  XML_NO_EMPTY : {type : 'bool', default : false},
  XML_IGNORE_NAMESPACE : {type : 'bool', default : false},

  # Should probably never be changed
  DEVICE_ONLINE_THRESHOLD : {type : 'int', default : 4000}
```

真实配置文件为*config/config.json*

#### 三个主要服务

- cwmp：遵循CWMP协议的服务器程序，也是整个项目最主要的程序
- nbi：开启RESTFUL API服务器，主要供[genieacs-gui](https://github.com/genieacs/genieacs-gui "genieacs-gui")控制cwmp服务使用
- fs：静态文件服务器，主要供CPE下载固件或配置文件

#### 修改服务器名标识

文件*lib/soap.js*第*25*行：``const SERVER_NAME = `GenieACS/${require("../package.json").version}`;``

#### 启动http basic auth

1. 安装[http-auth](https://github.com/http-auth/http-auth "http-auth")依赖
2. 使用http-auth的basic方法在启动服务器时加入HTTP AUTH
3. 参考以下源码修改*lib/server.coffee*

```coffee
# 注入basic方法
http = require 'http'
auth = require 'http-auth'
basic = auth.basic({
  realm: "Restricted"
  }, (username, password, cb) ->
    cb(username == "acs" && password == "acs")
)
```

```coffee
# ceateServer方法执行时使用
server = http.createServer(basic, listener)
server.on('connection', onConnection) if onConnection?
```

#### 主动访问CPE时，提供认证信息

参考[官方说明](https://github.com/genieacs/genieacs/wiki/GenieACS-Auth-Config#acs-to-cpe "官方说明")

修改*config/auth.js*

```js
"use strict";

function connectionRequest(deviceId, url, username, password, callback) {
  return callback('username', 'password');
}

exports.connectionRequest = connectionRequest;

```