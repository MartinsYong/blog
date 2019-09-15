---
title: Vue 的 tips 与 tricks
date: 2019-09-14 23:11:32
categories: 技术
tags: Vue
---

下面介绍一些 Vue 实用的姿势与技巧。

#### [tip] 妙用 watchers

在 watchers 中，可以直接使用函数的字面量名称；其次，声明 `immediate:true` 表示创建组件时立马执行一次

```js
watch: {
    searchInputValue:{
        handler: 'fetchPostList',
        immediate: true
    }
}
```

<!--more-->

#### [tip] 利用 filter

##### 理解过滤器

- 功能：对要显示的数据进行特定格式化后再显示。
- 注意：过滤器并没有改变原本的数据，需要对展现的数据进行包装。
- 使用场景：双花括号插值和 v-bind 表达式 (后者从 2.1.0+ 开始支持)。

##### 定义过滤器

组件内：
```js
filters: {
  capitalize: function (value) {
    if (!value) return ''
    value = value.toString()
    return value.charAt(0).toUpperCase() + value.slice(1)
  }
}
```

全局:
```js
Vue.filter('capitalize', function (value) {
  if (!value) return ''
  value = value.toString()
  return value.charAt(0).toUpperCase() + value.slice(1)
})
```

##### 使用过滤器

使用方法也简单，即在双花括号中使用管道符(pipeline) `|` 隔开

```html
<!-- 在双花括号中 -->
<div>{{ myData| filterName}}</div>
<div>{{ myData| filterName(arg)}}</div>
<!-- 在 v-bind 中 -->
<div v-bind:id="rawId | formatId"></div>
```

还可以串联：
```
{{ message | filterA | filterB }}
```

#### [tip] 不要在使用v-for的同一元素上使用v-if

Vue官方文档强烈建议**永远不要把 v-if 和 v-for 同时用在同一个元素上。**

一般我们在两种常见的情况下会倾向于这样做：

1. 为了过滤一个列表中的项目 (比如 `v-for="user in users" v-if="user.isActive")`。在这种情形下，请将 users 替换为一个计算属性 (比如 activeUsers)，让其返回过滤后的列表
2. 为了避免渲染本应该被隐藏的列表 (比如 `v-for="user in users" v-if="shouldShowUsers"`)。这种情形下，请将 v-if 移动至容器元素上

#### [tip] 在v-if/v-if-else/v-else中使用key

**如果一组v-if 与v-else的元素类型相同，最好使用属性key。**
这是因为Vue2.0引入虚拟DOM,为了避免不必要的DOM操作，虚拟DOM在虚拟节点映射到视图过程中，将虚拟节点与上一次渲染视图所使用的旧虚拟节点做对比，找出真正需要更新的节点来进行DOM操作。但有时如果两个本不相同的节点被识别为相同，便会出现意料之外的问题。如：

```html
<!-- 这种写法会出 bug 如果 input 里面有内容的话，点击切换后内容依然存在 -->
 <div v-if="flag">
    <label>a</label>
    <input type="text" />
 </div>
 <div v-else>
    <label>b</label>
    <input type="text" />
 </div>
 <button @click="flag = !flag">切换</button>
```

如果添加了属性key,那么在对比虚拟DOM时，则会认为它们是两个不同的节点，于是会将旧元素移除并在相同位置添加新元素，从而避免漏洞的出现。改为：
```html
// 最佳写法
 <div v-if="flag">
    <label>a</label>
    <input key="1" type="text" />
 </div>
 <div v-else>
    <label>b</label>
    <input key="2" type="text" />
 </div>
 <button @click="flag = !flag">切换</button>
```

#### [tip] 这些情况下不要使用箭头函数:
- 不应该使用箭头函数来定义一个生命周期方法
- 不应该使用箭头函数来定义 method 函数
- 不应该使用箭头函数来定义计算属性函数
- 不应该对 data 属性使用箭头函数
- 不应该使用箭头函数来定义 watcher 函数

#### [tip] v-for 循环中不推荐 index 作为 key

#### [tip] v-bind 是可以传对象
```html
<Component v-bind="{a: 1, b:'2'}"></Component>
```

相当于：
```html
<Component :a="1" b="2"></Component>
```

#### [tip] 不推荐多个组件同时声明插入同一个 slot

例如：
```html
<!--反例1-->
<parent>
    <son-a slot="body"></son-a>
    <son-b slot="body"></son-b>
</parent>
```

或者渲染列表：
```html
<!--反例2-->
<parent>
    <son v-for="item in list"
        :key="item.id" slot="body">
        {{item.content}}
    </son>
</parent>
```

推荐新建一个容器元素作为包裹，可以为 `template`:
```html
<parent>
    <template slot="body">
        <son v-for="item in list"
            :key="item.id">
            {{item.content}}
        </son>
    </template>
</parent>
```

#### [trick] 为 router 配上 key

我们在项目开发时，可能会遇到这样问题:当页面切换到同一个路由但不同参数地址时，比如 */detail/1*，跳转到 */detail/2*，页面跳转后数据竟然没更新？路由配置如下：

```
{
    path: "/detail/:id",
    name: "detail",
    component: Detail
}
```

这是因为 vue-router 会识别出两个路由使用的是同一个组件从而进行复用，并不会重新创建组件，而且组件的生命周期钩子自然也不会被触发，导致跳转后数据没有更新。那我们如何解决这个问题呢？
我们可以为 router-view 组件添加属性 key,例子如下：
```html
<router-view :key="$route.fullpath"></router-view>
```

如果key不相同，就会判定router-view组件是一个新节点，从而先销毁组件，然后再重新创建新组件。

#### [trick] 优化传入相同 props 给同层级不同组件的写法

假如有三个不同的组件，但都需要相同的 props：
```html
<template>
    <c-a prop-a="foo" :prop-b="false" prop-c="bar"></c-a>
    <c-b prop-a="foo" :prop-b="false" prop-c="bar"></c-b>
    <c-c prop-a="foo" :prop-b="false" prop-c="bar"></c-c>
</template>
```

可以利用 `is` 属性加列表渲染进行优化：
```html
<template>
    <Component
        v-for="comp in ['cA','cB','cC']"
        :is="comp" :key="comp"
        prop-a="foo" :prop-b="false" prop-c="bar">
    </Component>
</template>
```

其中，`Component` 可为任何标签

---

本文会持续更新……

### Ref

1. [Vue.js 一些开发技巧](https://github.com/ljianshu/Blog/issues/71)
2. [Vue.js最佳实践（五招让你成为Vue.js大师）](https://segmentfault.com/a/1190000014085613)
3. [官方风格指南](https://cn.vuejs.org/v2/style-guide/)
