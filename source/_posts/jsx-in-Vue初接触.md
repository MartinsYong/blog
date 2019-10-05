---
title: jsx in Vue 初接触
date: 2019-09-30 21:01:35
categories: 技术
tags: Vue
---

### 添加 jsx 支持

##### 对于 Babel7

安装 babel 依赖：

```
npm install @vue/babel-preset-jsx @vue/babel-helper-vue-jsx-merge-props
```

之后添加 preset 到 *.babelrc* 文件中：
```
{
  "presets": ["@vue/babel-preset-jsx"]
}
```

<!--more-->

##### 对于 Babel6

```
npm install\
  babel-plugin-syntax-jsx\
  babel-plugin-transform-vue-jsx\
  babel-helper-vue-jsx-merge-props\
  babel-preset-env\
  --save-dev
```

之后在 *.babelrc* 文件中添加
```
{
  "presets": ["env"],
  "plugins": ["transform-vue-jsx"]
}
```

### 最简单的例子：渲染根组件

```js
import Vue from 'vue'
import App from './app.vue'

new Vue({
    render() {
        return <App />
    }
}).mount('#app')
```


### 渲染函数

```
// 注册组件
Vue.compoenent('xxx', {
    render: function (createElement) {
      return createElement('h1')
    }
    props: {}
})
```

其中，`createElement` 函数接受三个参数，即下文的三元素。另外，还可以在组件实例内获取该函数的引用: `vm.$createElement`

### VNode 三元素

##### 1. HTML tag | component id：

##### 2. data：数据对象

##### 3. [VNode...] or String：子VNodes

具体三元素在 jsx 上的写法如下：
```html
<tagName ...data>...VNodes</tagName>
```

特别需要注意的是 data 数据对象，官方说明如下：
```js
{
  // 与 `v-bind:class` 的 API 相同，
  // 接受一个字符串、对象或字符串和对象组成的数组
  'class': {
    foo: true,
    bar: false
  },
  // 与 `v-bind:style` 的 API 相同，
  // 接受一个字符串、对象，或对象组成的数组
  style: {
    color: 'red',
    fontSize: '14px'
  },
  // 普通的 HTML 特性
  attrs: {
    id: 'foo'
  },
  // 组件 prop
  props: {
    myProp: 'bar'
  },
  // DOM 属性
  domProps: {
    innerHTML: 'baz'
  },
  // 事件监听器在 `on` 属性内，
  // 但不再支持如 `v-on:keyup.enter` 这样的修饰器。
  // 需要在处理函数中手动检查 keyCode。
  on: {
    click: this.clickHandler
  },
  // 仅用于组件，用于监听原生事件，而不是组件内部使用
  // `vm.$emit` 触发的事件。
  nativeOn: {
    click: this.nativeClickHandler
  },
  // 自定义指令。注意，你无法对 `binding` 中的 `oldValue`
  // 赋值，因为 Vue 已经自动为你进行了同步。
  directives: [
    {
      name: 'my-custom-directive',
      value: '2',
      expression: '1 + 1',
      arg: 'foo',
      modifiers: {
        bar: true
      }
    }
  ],
  // 作用域插槽的格式为
  // { name: props => VNode | Array<VNode> }
  scopedSlots: {
    default: props => createElement('span', props.text)
  },
  // 如果组件是其它组件的子组件，需为插槽指定名称
  slot: 'name-of-slot',
  // 其它特殊顶层属性
  key: 'myKey',
  ref: 'myRef',
  // 如果你在渲染函数中给多个元素都应用了相同的 ref 名，
  // 那么 `$refs.myRef` 会变成一个数组。
  refInFor: true
}
```

由此可见，它跟 react 的 props 有很大不同。

##### 例子

```
...
(
    <el-checkbox {...{props: {value: this.a, 'true-label': '1', 'false-label': '0'}, on: {input: this.handleInput}}}>
        勾选我
    </el-checkbox>
)
...
```

### Ref

- [vuejs/jsx](https://github.com/vuejs/jsx)
- [渲染函数](https://cn.vuejs.org/v2/guide/render-function.html)
