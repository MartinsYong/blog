---
title: Vue 高阶组件三剑客
date: 2019-10-05 13:48:21
categories: 技术
tags: Vue
---

让我们直接进入正题，这三剑客就是指 `$props`、`$attrs`、`$listeners`。

### API 定义

先看官方文档定义然后再慢慢展开：

> `vm.$props`: 当前组件接收到的 props 对象。
> `vm.$attrs`: 包含了父作用域中不作为 prop 被识别 (且获取) 的特性绑定 (class 和 style 除外)。
> `vm.$listeners`: 包含了父作用域中的 (不含 .native 修饰器的) v-on 事件监听器。

<!--more-->

### $props

定义简单明了，意思是我们可以从 `$props` 获取组件接收到的 props 对象，这个 props 就是指组件本身定义的 props。比如:
```
<template>
    <div>{{a}}&{{b}}&{{c}}</div>
<template>

<script>
export default {
    name: 'abc',
    props: ['a', 'b', 'c']
}
</script>
```

此组件在创建之后，即可访问该实例的 `$props`，获取到 `a`、`b` 和 `c` 三个属性及值。

当然这里有两种情况需要考虑：
1. 父作用域传入了值：那我们可以直接获取去得到这个传入的值
2. 父作用域没有传入值：如果有定义此 prop 的默认值，那么我们会得到此默认值，否则会得到 `undefined`

### $attrs

如果父作用域传了一些组件未定义的值，那我们就可以从 `$attrs` 中获取得到。

比如我们基于上面那个例子，在父作用域给它传其他值：
```
<template>
    <abc :a="1" :b="false" c="c" :d="2"></abc>
</template>

<script>...</script>
```

那么我们可以访问 abc 组件实例中的 `$attrs` 获取到：
```
{
    d: 2
}
```

因为属性 `d` 没有在 abc 组件的 `props` 中。

#### 关于 inheritAttrs

如果 `d` 的值在模板中以普通 HTML attrs 的方式传入：
```
...
<abc :a="1" :b="false" c="c" d="2"></abc>
...
```

我们同样可以在 `$attrs` 中获取到属性 `d`：
```
{
    d: "2"
}
```

但是我们也可以在真实 DOM 树中看到：
```html
...
<div data-v-abc12345 d="2">
...
</div>
...
```

这个属性被应用此组件在真实 DOM 的根元素上。如果你不希望这样的情况发生，则可以设置组件的 `inheritAttrs` 值为 `false`。

### $listeners

`$listeners` 跟 `$attrs` 比较相似，`$listeners` 可以获取到父作用域在此组件上设置的所有事件监听（但不包括 `.native` 修饰器的），比如：
```
<template>
    <abc @click="clickHandle" @update-value="update"></abc>
</template>

<script>...</script>
```

那么 abc 实例的 `$listeners` 为
```
{
    'click': Function
    'update-val': Function
}
```

这些 `Function` 都是父作用域上所定义的函数对象。

### 怎么用

我们知道：Vue 模板中的指令 `v-bind` 与 `v-on` 都支持传入对象，因此有：
```
v-bind="$props"
v-bind="$attrs"
v-on="$listeners"
```

结合此特性，再加上三剑客各自的特点，我们可以更方便地写出 Vue 的高阶组件。

此外，对于 `$props`，[官方 github repo](https://github.com/vuejs/vue/issues/4571) 上还有一个很好的例子：
```
<template>
  <modal v-bind="$props">
    <input v-model="inputValue" :placeholder="placeholder" />
  </modal>
</template>

<script>
import Modal from './Modal.vue'

export default {
  props: {
    ...Modal.props,
    value: {},
    placeholder: String,
  },

  // ...
}
</script>
```

### Ref

- [Vue.js API 文档](https://cn.vuejs.org/v2/api)
- [Vue.js 实用技巧](https://zhuanlan.zhihu.com/p/25623356)
