---
title: html2canvas 使用笔记
date: 2019-09-30 21:01:35
categories: 技术
tags: [plugins, html2canvas]
---

### 介绍

此插件 [html2canvas](https://html2canvas.hertzen.com/) 可以说是一个 js 截屏插件。原理就像它名字所描述的一样：将 HTML 元素节点转换为 canvas 图层。

转成 canvas 图片后，我们就可以对它进行各种操作，包括展示、编辑还有图片导出。

### 简单使用

步骤：
1. 获取目标元素节点
2. 利用 html2canvas 生成 canvas 图层
3. 按需使用该图层

```js
// 比如最简单的展示
let target = document.querySelector('.containter')

html2canvas(target).then(canvas => {
    document.appendChild(canvas)
})

// 或者导出 base64 图片
html2canvas(target).then(canvas => {
    console.log(canvas.toDataURL('image/png'))
    // data:image/png;base64,.......
})
```

<!--more-->

##### 可配置参数

html2canvas 方法还有第二个参数，为配置参数对象，一些比较重要的列一下：

属性名 | 描述
---|---
allowTaint | 是否加载外部图片
backgroundColor | 背景颜色，默认为 '#ffffff'，可设置 null 为透明
imageTimeout | 图片加载超时时长
logging | 是否打印错误信息，默认为 true
proxy | 异源图片加载使用代理
useCORS | 是否使用跨域方法加载异源图片
width | canvas 宽度
height | canvas 高度

### 截图不全

如果不设置 canvas 图层宽高，该插件会默认把一整个元素截下来。但是，有时候会出现截不全的情况。

笔者碰到这种情况都是因为目标元素被滚动了所致。解决方法可以是在使用 html2canvas 之前先将视窗和目标元素的滚动重置：
```js
window.scrollTo(0, 0)
targetElement.scrollTo(0, 0)

// ...html2canvas(targetElement)
```

### 加载外部图片并导出

默认情况下，html2canvas 不会去加载目标元素内部的异源图片，比如：
```
https://www.baidu.com/img/bd_logo1.png
```

除非在配置参数里面开启 `allowTaint`:
```js
html2canvas(elem, {
    allowTaint: true
})
```

这样，外部图片就能在 canvas 上正常显示。

然而，生成 canvas 图层的状态是 `tainted` 的，翻译过来的意思是受污染的。这样的 canvas 基于安全考虑是不能被导出的，即不能 `toBlob` 或者 `toDataURL`。

chrome 浏览器会报这样的错误提示：

> Uncaught DOMException: Failed to execute 'toDataURL' on 'HTMLCanvasElement': Tainted canvases may not be exported.

**html2canvas 提供了以下两种方法来解决：**

#### CORS

启用跨域访问，配置参数如下：
```js
{
    // ...
    useCORS: true
    // ...
}
```

这样，html2canvas 会在请求图片的时候加上头 `Origin: martinsyong.github.io`。

这种方法必须要图片服务器的支持，即响应加上一堆头：`Access-control-allow-*`

#### 使用代理

我们可以在自己的服务器上设置代理来转发此图片，html2canvas 配置参数加上 proxy，即代理地址。

```
{
    proxy: '/proxy'
}
```

实际图片请求的地址为：
```
https://localhost/proxy?url=https%3A%2F%2Fexample.com%2Fxx.png&responseType=blob
```

这种方法比较灵活，而且较容易实现。官方也给出了 proxy 服务端的示例代码：<https://github.com/niklasvh/html2canvas-proxy-nodejs>

### Ref

1. [启用 CORS](https://developer.mozilla.org/zh-CN/docs/Web/HTML/CORS_enabled_image)
2. [解决canvas图片getImageData,toDataURL跨域问题](https://www.zhangxinxu.com/wordpress/2018/02/crossorigin-canvas-getimagedata-cors/)
