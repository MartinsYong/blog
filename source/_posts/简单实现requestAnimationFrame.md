---
title: 简单实现 requestAnimationFrame
date: 2019-08-03 12:31:00
categories: 技术
tags: [javascript,动画]
---

`requestAnimationFrame` （还有对应的 `cancelAnimationFrame`） 是新手（没错，说的是笔者本人）学习 JavaScript 实现原生动画的必经之路。这篇文章只单单讲**如何简单实现这个函数**，而如果你想了解关于 `requestAnimationFrame` 的概念及原理，请浏览本文最下方的参考文章。

### 为什么要自己实现？

笔者第一次决定用 JavaScript 实现动画时，就吃了亏。因为 `requestAnimationFrame` 在 IE9 及以下版本是不兼容的。详情可以看 [caniuse](https://caniuse.com/#search=requestanimationframe)。

然后就没办法，这个动画要能在 IE9 上跑，不然直接可以使用 CSS3。所以只能自己尝试去实现 polyfill。

我们在使用 `requestAnimationFrame` 时候，兼容性是先要考虑的（其实很多新的 API 也需要考虑这个问题）。而在兼容性不满足的情况下，我们就需要 polyfill。

<!--more-->

### 测试先行

下面这个测试用例主要使用了 Mocha 作为测试框架。其中 `rAF` 是简写，**16ms** 为动画帧间隔。

```js
describe('rAF', () => {
    it('tick', done => {
        let start = new Date().getTime();
        let times = 0;
    
        rAF(function tick (timeStamp) {
            console.log(timeStamp);
            if (++times === 10) {
                const interval = (new Date().getTime() - start);
                assert(interval >= 9 * 16, `should take at least ${times - 1} frames worth of wall time: ${interval}ms`);
                done();
            } else {
                rAF(tick);
            }
        });
    })
});
```

这个用例简单且直接，将 `requestAnimationFrame` 运行了 10 次，然后判断运行时间长度是否大于 9 个动画帧的时间。

然后自己写了一个最简单的实现：
```js
function rAF (fn) {
    return setTimeout(() => {
        fn(+new Date());
    }, 16);
}
```

通过测试。**但是有个问题是：输出的时间戳之间的差值都大于 16，偏差为 1~3 左右。**

而且，第一帧没有立即运行。所以我们还需再下功夫。

### 全面实现

在这里，还有一段小插曲。

笔者还在 GitHub 上一个著名的库中找到了 `requestAnimationFrame` 的简单实现：

```js
var prev = new Date().getTime();
function rAF(fn) {
  var curr = new Date().getTime();
  var ms = Math.max(0, 16 - (curr - prev));
  var req = setTimeout(fn, ms);
  prev = curr;
  return req;
}
```

但是，这段代码通过不了测试。当时，笔者就很纳闷了：“怎么可能呢，是不是我测试搞错了？”

然后笔者又用这个测试用例反复测试了浏览器自带的 `requestAnimationFrame`，除了有一点点偏差之外没有发现任何问题。

然而当时笔者反复 debug 了很多次依然找不出这段 GitHub 上的代码哪里出错了。直到看到了参考文章上面的代码：

```js
var lastTime = 0;
window.requestAnimationFrame = function(callback) {
    var now = Date.now();
    var nextTime = Math.max(lastTime + 16, now);
    return setTimeout(function() { callback(lastTime = nextTime); },
                      nextTime - now);
};
```

笔者恍然大悟，原来是计算 `prev` 的 bug：

```js
var prev = new Date().getTime();
function rAF(fn) {
  var curr = new Date().getTime();
  var ms = Math.max(0, 16 - (curr - prev));
  var req = setTimeout(fn, ms);
  prev = curr + ms;  // 这里应该是这样
  return req;
}
```

然后笔者立刻提了 PR。（笑）

**这段插曲警醒了笔者：在使用开源代码时，须先看测试和跑测试。**

### 最后附上完整的代码

包含了 `cancelAnimationFrame`

```js
// 判断宿主环境（因为在 nodejs 上进行开发）
const root = typeof window === 'undefined' ? global : window;
// 60fps
const frameInterval = Math.floor(1000 / 60);

let last = new Date().getTime();
function fallback (fn) {
    const curr = new Date().getTime();
    const timeToRun = Math.max(0, frameInterval - (curr - last));
    last = curr + timeToRun;
    return setTimeout(() => {
        fn(last);
    }, timeToRun);
}

const cancel = root.cancelAnimationFrame
    || root.webkitCancelAnimationFrame
    || root.mozCancelAnimationFrame
    || clearTimeout;

exports.rAF = root.requestAnimationFrame
    || root.webkitRequestAnimationFrame
    || root.mozRequestAnimationFrame
    || fallback.bind(root);

exports.cAF = id => {
    cancel.call(root, id);
}
```

### Ref

[1] [requestAnimationFrame 知多少？](https://www.cnblogs.com/onepixel/p/7078617.html)

还有一些值得看一下的 requestAnimationFrame 源码：

1. <https://github.com/chrisdickinson/raf>
2. <https://github.com/kof/animation-frame>