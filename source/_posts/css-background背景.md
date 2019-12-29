---
title: css background背景
date: 2017-03-19 13:44:55
categories: 技术
tags: css
---

### 前言

昨天面试前端的时候被面试官问background的问题却答不上几点。唉～复习一下吧。

---

### 简要描述

属性 | 描述
---|---
background-color	  |  规定要使用的背景颜色。
background-position	  |  规定背景图像的位置。
background-size	      |  规定背景图片的尺寸。
background-repeat	  |  规定如何重复背景图像。
background-origin	  |  规定背景图片的定位区域。
background-clip	      |  规定背景的绘制区域。
background-attachment |	 规定背景图像是否固定或者随着页面的其余部分滚动。
background-image	  |  规定要使用的背景图像。

<!--more-->

### 具体研究

#### background-color 

- 默认值为transparent，即透明
- 可令值为某个rbg颜色
- 这种颜色会填充元素的内容、内边距和边框区域，扩展到元素边框的外边界（但不包括外边距）

#### background-position

- 默认值为0% 0%，分别表示水平值和垂直值，可用像素来描述（数值不带单位）
- 可用centre/bottom/top/left/right来定义两个值，如```top left```

#### background-size

- 默认值为auto，一般是图片的大小
- 可填写像素值和百分比，格式为```50 50```或```50% 50%```，分别为宽度值和高度值
- 两个特殊的值，均可先理解为按原图像宽高比拉伸以覆盖整个容器：
    1. cover，真正覆盖整个容器，但可能因容器和原图像的宽高比不同而无法显示完整的图像，即有一部分会隐藏起来
    2. contain，可能因容器和原图像的宽高比不同而无法完全覆盖整个容器，图像完整显示

#### background-repeat

- 两个常用的值：repeat和no-repeat，默认repeat的模式为水平和垂直方向都重复
- 另两值：repeat-x和repeat-y，顾名思义.....
- inherit：继承爸爸
- 配合background-size会有加成，读者可以试试

#### background-origin 和 background-clip

- 它们的值均有border-box/padding-box/content-box
- 对比一下更好理解：

```css
div
{
border:1px solid black;
padding:35px;
background-image:url('图片地址');
background-repeat:no-repeat;
background-position:left;
}
#div1
{
background-origin:border-box;
background-clip: content-box;
}
#div2
{
background-origin:content-box;
background-clip:border-box;
}
```

![image](https://test-10058651.cos.ap-shanghai.myqcloud.com/css_background%E8%83%8C%E6%99%AF_1.png)

#### background-attachment

- 默认值为scroll
- 有趣的值：fixed，多个容器、多个背景使用时会有视差效果
- inherit：继承爸爸

#### background-image

- 常用方法：```url('图像地址')```
- css3中新增多重背景功能：```url('图像地址1'),url('图像地址2'),url('图像地址3')```

### Reference

[w3school](http://www.w3school.com.cn/cssref/index.asp#background)
