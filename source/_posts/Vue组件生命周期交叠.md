---
title: Vue 组件生命周期交叠
date: 2019-08-25 14:31:21
categories: 技术
tags: Vue
---

### 引子

笔者这周在开发上面遇到了一个 Vue 的问题，就是文章标题所提到的。笔者觉得这个问题非常普遍，但是鲜有资料，所以拿出来分享并一起探讨一下。

首先，说一下当时问题发生的一个具体的场景：
1. 不同页面组件都需监听只由父组件触发的特定事件（如 `myevent`）
2. 这些页面组件在同一时间内只会挂载一个
3. 当前页面在此事件触发之后需要实现特定的业务逻辑

那好，实现这样的场景需求其实也挺简单：只需在各个页面组件创建时监听这个事件，销毁时取消监听就可以了。

然而，问题出现了。

<!--more-->

刚开始还能正常实现，事件正常触发。但是切换了页面组件后，就无法正常实现：父组件触发了事件，但是页面组件并没有执行相应的特定业务。

### 问题分析

我们先了解一下事件监听和取消监听的 API：

- 监听：
```
$on( event, callback )
```

- 取消监听：
```
$off( [event, callback] )
```

我们知道：`$off` 函数只传 `event` 参数的话，bus 会把所有 listeners 给注销。当时笔者就是用了这种注销方式。

另外，笔者在实现页面组件代码时候，把 `$on` 放在了 `created` hook 中，把 `$off` 放在了 `destroyed` hook 中。

好，这两个写法都是问题的关键：
- `$off` 注销全部的 listeners
- 使用 hook: `created` 和 `destroyed`

结果导致了页面组件切换时，如 A 切换成 B，A 销毁时把 B 新建的监听给注销掉。

到这里，读者们就会有疑问：不是 A 销毁了再 B 新建码吗？A 怎么会影响到 B？

### 生命周期交叠

对于 Vue 的实例生命周期，了解过 Vue 的读者都很清楚。如 hook 的执行顺序：
1. beforeCreate
2. created
3. beforeMount
4. mounted
5. beforeUpdate
6. updated
7. beforeDestroy
8. destoryed

那如果是多个实例呢，它们之间的生命周期是如何表现？

如父子组件的创建和销毁。这个，大家都可能比较了解，整个过程跟执行栈切换相似：创建时先创建父组件，销毁时先销毁子组件。

那么，如果是前面提到的情况呢：同级组件发生切换。大家的答案可能都是先销毁了已有的，再创建新的。其实，这个答案并不完全。笔者之前也是这样的看法，直到真正遇到了问题。

实际上，它们的 hook 顺序是这样的：
```
A: beforeCreate
A: created
A: beforeMount
A: mounted
A: beforeUpdate
A: updated
...
-> 执行切换
B: beforeCreate
B: created
B: beforeMount
A: beforeDestroy
A: destroyed
B: mounted
...
```

**是不是很出乎意料？那 B 的子组件呢？这里强烈建议读者去实践试验一下。**

因此，实际发送切换后，B 先创建实例准备挂载，然后 A 执行销毁，再到 B 完成挂载。这样的 hook 顺序导致了上面问题的出现。

那么，如果我们在 `mounted` 了之后才注册这个事件，就能解决这个问题。

### 最后

其实，不只是路由页面组件切换会导致周期交叠的情况发生，简单的 `v-if` 与 `v-else` 实现**不同组件**的即时切换也能导致。

如这个实例：
[vuecrosslifecycle](https://codesandbox.io/s/vuecrosslifecycle-g22px)。

一开始点击 emit 是有对应信息输出在控制台中，但是点击 switch 之后再点击 emit 就没有输出了。


### Ref

[vue中eventbus被多次触发（vue中使用eventbus踩过的坑）](https://www.jianshu.com/p/fde85549e3b0)
