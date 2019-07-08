---
title: genieacs源码剖析
date: 2018-11-05 17:15:12
categories: 技术
tags: 通信
---

> A fast and lightweight TR-069 Auto Configuration Server (ACS)

### 项目地址

[Genieacs](https://github.com/genieacs/genieacs)

### 目录结构

```
├── bin 存放入口文件
│   ├── genieacs-cwmp 主体程序可执行脚本
│   ├── genieacs-fs 文件服务可执行脚本
│   └── genieacs-nbi RESTFUL API服务可执行脚本
├── config 存放配置参数文件及拓展插件文件
│   ├── auth-sample.js
│   ├── auth.js
│   ├── config-sample.json
│   ├── config.json
│   └── ext-sample.js
├── debug
├── lib 存放核心文件
│   ├── api-functions.js
│   ├── auth.js 处理http认证
│   ├── cache.js
│   ├── cluster.js 调用cluster模块逻辑
│   ├── common.js 存放处理变量的方法
│   ├── config.js 获取配置参数
│   ├── cwmp.js
│   ├── db.js 数据库查询
│   ├── default-provisions.js
│   ├── device.js
│   ├── extension-wrapper.js
│   ├── extensions.js
│   ├── fs.js
│   ├── gpn-heuristic.js
│   ├── instance-set.js
│   ├── local-cache.js
│   ├── logger.js 日志
│   ├── nbi.js
│   ├── path-set.js
│   ├── query.js
│   ├── sandbox.js
│   ├── scheduling.js
│   ├── server.js 启动http服务
│   ├── session.js
│   ├── soap.js XMLSOAP处理(包括解析和打包)
│   └── versioned-map.js

```

<!--more-->

### 正文

#### 入口

*bin*目录下三个文件均为入口启动文件，代表三种不同的服务。对比可看出，三个文件的逻辑一致。

```js
// genieacs-cwmp

#!/usr/bin/env node
var path = require('path');
var fs = require('fs');

// 获取项目绝对路径
var dir = path.resolve(path.dirname(fs.realpathSync(__filename)), '..');
process.chdir(dir);

// 调用cluster，启动cwmp服务
var cluster = require(path.resolve(dir, 'lib/cluster'));
cluster.start('cwmp');
```

接下来是cluster，cluster模块是nodejs默认自带的，用于同时启动多个进程。[具体介绍](https://www.nodeapp.cn/cluster.html) \ [原理](https://cnodejs.org/topic/56e84480833b7c8a0492e20c)

```js
// cluster.js

// 返回依赖版本信息
function getDependencyVersions() {...}

// 返回配置参数
function getConfig() {...}

// 重启worker
function restartWorker(worker, code, signal) {...}

// 启动服务
function start(service) {
// ...

// 设置集群参数
cluster.setupMaster({
    exec: "lib/server",
    args: [service]
});

let workerCount = config.get(`${service.toUpperCase()}_WORKER_PROCESSES`);

if (!workerCount) workerCount = Math.max(2, require("os").cpus().length);

// 派生子进程
for (let i = 0; i < workerCount; ++i) cluster.fork();

}

```

最后是server.js，用于启动http服务与数据库连接。

#### 处理请求

*lib*目录下有对应三个服务的文件:*cwmp.js*、*nbi.js*、*fs.js*, 这三个文件都暴露了**listener**方法供*server.js*使用，用于处理http请求。下面对*cwmp.js*进行展开。

```js
// ...

// 状态记录
const stats = {
  concurrentRequests: 0,
  totalRequests: 0,
  droppedRequests: 0,
  initiatedSessions: 0
};

// ...

// 响应cpe inform请求
function inform(sessionContext, rpc) {
    // 记录
    session.inform(sessionContext, rpc.cpeRequest, (err, acsResponse) => {
    if (err) return void throwError(err, sessionContext.httpResponse);
    // 将数据打包为SOAP格式
    const res = soap.response({
      id: rpc.id,
      acsResponse: acsResponse,
      cwmpVersion: sessionContext.cwmpVersion
    });
    // 设置cookie, 内容主要为sessionId
    const cookiesPath = config.get("COOKIES_PATH", sessionContext.deviceId);
    if (cookiesPath) {
      res.headers["Set-Cookie"] = `session=${
        sessionContext.sessionId
      }; Path=${cookiesPath}`;
    } else {
      res.headers["Set-Cookie"] = `session=${sessionContext.sessionId}`;
    }
    // 发送响应
    writeResponse(sessionContext, res);
  });
}

// ...

// 获取session
function getSession(connection, sessionId, callback) {...}

// ...

// 处理请求
function processRequest(sessionContext, rpc) {
    if (rpc.cpeRequest) {
        // 判断不同的cpe请求
        if (rpc.cpeRequest.name === "Inform") {
          // 记录日志
          logger.accessInfo({
            sessionContext: sessionContext,
            message: "Inform",
            rpc: rpc
          });
          // 处理inform请求
          inform(sessionContext, rpc);
        }
        else if(...) {...}
        // ...
    }
}

function listener(httpRequest, httpResponse) {
  // ...
  
  // 获取sessionId
  let sessionId;
  // Separation by comma is important as some devices don't comform to standard
  const COOKIE_REGEX = /\s*([a-zA-Z0-9\-_]+?)\s*=\s*"?([a-zA-Z0-9\-_]*?)"?\s*(,|;|$)/g;
  let match;
  while ((match = COOKIE_REGEX.exec(httpRequest.headers.cookie)))
    if (match[1] === "session") sessionId = match[2];

  // ...

  let stream = httpRequest;
  
  // ...

  // 数据量统计
  const chunks = [];
  let bytes = 0;
  stream.on("data", chunk => {
    chunks.push(chunk);
    bytes += chunk.length;
  });

  stream.on("end", () => {
    // 拷贝一份请求数据
    const body = Buffer.allocUnsafe(bytes);
    let offset = 0;
    for (const chunk of chunks) {
      chunk.copy(body, offset, 0, chunk.length);
      offset += chunk.length;
    }

    function parsedRpc(sessionContext, rpc, parseWarnings) {
      // ...
      
      // 处理请求
      processRequest(sessionContext, rpc);
    }
    // 尝试同步session
    getSession(httpRequest.connection, sessionId, (err, sessionContext) => {
      if (err) return void throwError(err, httpResponse);

      if (sessionContext) {
        sessionContext.httpRequest = httpRequest;
        sessionContext.httpResponse = httpResponse;
        if (
          sessionContext.sessionId !== sessionId ||
          sessionContext.lastActivity + sessionContext.timeout * 1000 <
            Date.now()
        ) {
          logger.accessError({
            message: "Invalid session",
            sessionContext: sessionContext
          });

          httpResponse.writeHead(400, { Connection: "close" });
          httpResponse.end("Invalid session");
          stats.concurrentRequests -= 1;
          return;
        }
      } else if (stats.concurrentRequests > MAX_CONCURRENT_REQUESTS) {
        // Check again just in case device included old session ID
        // from the previous session
        httpResponse.writeHead(503, { "Retry-after": 60, Connection: "close" });
        httpResponse.end("503 Service Unavailable");
        stats.droppedRequests += 1;
        stats.concurrentRequests -= 1;
        return;
      }
      // 解析请求发送过来的xml数据
      const parseWarnings = [];
      let rpc;
      try {
        rpc = soap.request(
          body,
          sessionContext ? sessionContext.cwmpVersion : null,
          parseWarnings
        );
      } catch (error) {
        logger.accessError({
          message: "XML parse error",
          parseError: error.message.trim(),
          sessionContext: sessionContext || {
            httpRequest: httpRequest,
            httpResponse: httpResponse
          }
        });
        httpResponse.writeHead(400, { Connection: "close" });
        httpResponse.end(error.message);
        stats.concurrentRequests -= 1;
        return;
      }
      // 已存在session的话
      if (sessionContext) {
        if (
          (rpc.cpeRequest && rpc.cpeRequest.name === "Inform") ||
          !sessionContext.rpcRequest ^ !(rpc.cpeResponse || rpc.cpeFault)
        ) {
          logger.accessError({
            message: "Bad session state",
            sessionContext: sessionContext
          });
          httpResponse.writeHead(400, { Connection: "close" });
          httpResponse.end("Bad session state");
          stats.concurrentRequests -= 1;
          return;
        }
        return void parsedRpc(sessionContext, rpc, parseWarnings);
      }
      // 仅允许inform请求
      if (!(rpc.cpeRequest && rpc.cpeRequest.name === "Inform")) {
        logger.accessError({
          message: "Invalid session",
          sessionContext: sessionContext || {
            httpRequest: httpRequest,
            httpResponse: httpResponse
          }
        });
        httpResponse.writeHead(400, { Connection: "close" });
        httpResponse.end("Invalid session");
        stats.concurrentRequests -= 1;
        return;
      }
      // 新建一个session
      stats.initiatedSessions += 1;
      const deviceId = common.generateDeviceId(rpc.cpeRequest.deviceId);

      session.init(
        deviceId,
        rpc.cwmpVersion,
        rpc.sessionTimeout || config.get("SESSION_TIMEOUT", deviceId),
        (err, _sessionContext) => {
          if (err) return void throwError(err, httpResponse);

          _sessionContext.httpRequest = httpRequest;
          _sessionContext.httpResponse = httpResponse;
          _sessionContext.sessionId = crypto.randomBytes(8).toString("hex");
          httpRequest.connection.setTimeout(_sessionContext.timeout * 1000);

          getDueTasksAndFaultsAndOperations(
            deviceId,
            _sessionContext.timestamp,
            (err, dueTasks, faults, operations, cacheUntil) => {
              if (err) return void throwError(err, httpResponse);

              _sessionContext.tasks = dueTasks;
              _sessionContext.operations = operations;
              _sessionContext.cacheUntil = cacheUntil;
              _sessionContext.faults = faults;
              _sessionContext.retries = {};
              for (const [k, v] of Object.entries(_sessionContext.faults)) {
                if (v.expiry >= _sessionContext.timestamp) {
                  // Delete expired faults
                  delete _sessionContext.faults[k];
                  if (!_sessionContext.faultsTouched)
                    _sessionContext.faultsTouched = {};
                  _sessionContext.faultsTouched[k] = true;
                } else {
                  _sessionContext.retries[k] = v.retries;
                }
              }
              parsedRpc(_sessionContext, rpc, parseWarnings);
            }
          );
        }
      );
    });
  });
}
```

#### preset 功能

官方wiki中并没有详细提及到此功能，以下将对此进行展开：

*preset*在数据库中单独开一个表，字段主要有channel、weight、schedule、events、precondition、configurations。

*channel* 类型为string，默认为"default"，主要用来作为过滤发生错误的preset的依据。如果一个preset执行的时候发生了错误（fault），那么同一channel的preset都将不会被执行。

*weight* 类型为number，默认为0，主要用来排序，规则为升序。weight越低，越先被执行。

*events* 类型为object，默认为空。主要用来作为preset的启动条件。格式为
```js
{
    "0 BOOTSTRAP": false,
    "1 BOOT": true
}
```

*schedule* 类型为string，默认为空。指preset运行的周期。一般情况下，符合条件的设备每一次inform到来时都会执行一次。而配置此字段可指定preset运行的周期。格式为"duration cron", 如`"300 0 0 0 * * ?"` 指每天执行一次。duration一般指设备inform的频率(官方并没介绍，此结论是笔者通过实验得出)，单位为秒。

*precondition* 类型为JSON string，用于筛选设备。

*configurations* 类型为array，指本preset的所有配置项。

##### 关于批量重启、重置和更新固件

在preset的配置项中，有一个非常重要的功能——*provision*。

通常情况下，用户可定义自己的**provision脚本**，用于实现更加复杂的操作，具体怎样不在此展开，可参考[官方wiki介绍](https://github.com/genieacs/genieacs/wiki/Provisions)

回到怎么实现重启、重置和更新固件的问题上，用户一般可以发布针对某个设备的任务来执行这样的操作。但是任务不能实现设备批量筛选、时间计划*cron*等功能。

官方源码中为我们提供了方法来实现,就是*provision*。

```js
// default-provisions.js

...
// 重启
function reboot(sessionContext, provision, declarations, startRevision, endRevision) {
  declarations.push([["Reboot"], 1, {value: 1}, null, {value: [sessionContext.timestamp]}]);

  return true;
}

// 重置
function reset(sessionContext, provision, declarations, startRevision, endRevision) {
  declarations.push([["FactoryReset"], 1, {value: 1}, null, {value: [sessionContext.timestamp]}]);

  return true;
}

// 下载
function download(sessionContext, provision, declarations, startRevision, endRevision) {
  let alias = [["FileType"], provision[1] || "", ["FileName"], provision[2] || "",
    ["TargetFileName"], provision[3] || ""];

  declarations.push([["Downloads", alias], 1, {}, 1]);
  declarations.push([["Downloads", alias, "Download"], 1, {value: 1}, null,
    {value: [sessionContext.timestamp]}]);

  return true;
}

...

```

```js
// session.js

...
function runProvisions(sessionContext,provisions,startRevision,endRevision,callback) {
    ...
    const allProvisions = provisionsCache.get(sessionContext);

    for (const [j, provision] of provisions.entries()) {
      if (!allProvisions[provision[0]]) {
        allDeclarations[j] = [];
        allClear[j] = [];
        if (defaultProvisions[provision[0]]) {
          done =
            defaultProvisions[provision[0]](
              sessionContext,
              provision,
              allDeclarations[j],
              startRevision,
              endRevision
            ) && done;
        }

      continue;
    }
    ...
}
...

```

根据以上源码，我们只要将provision的name写成以上三个函数名之一(reboot、reset、download)就可以实现对应的操作。

而更新固件还需要额外加三个参数：FileType、FileName、TargetFileName，须写在*argument*中，用`,`进行分隔，例子抓包如下:

```json
{"channel":"12","weight":0,"precondition":"{\"Device.DeviceInfo.SerialNumber\":\"xxxxxxxxxxxxx\"}","configurations":[{"type":"provision","name":"download","args":["1 Firmware Upgrade Image","ruijie.bin","ruijie.bin"]}],"schedule":"","events":{}}
```