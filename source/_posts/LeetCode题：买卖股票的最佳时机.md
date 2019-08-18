---
title: LeetCode题：买卖股票的最佳时机
date: 2016-08-18 13:31:21
categories: 技术
tags: 算法
---

记录一道 LeetCode 题的个人思路及其演进过程。

该题出自 [LeetCode 121](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock/)。

### 问题描述

> 给定一个数组，它的第 i 个元素是一支给定股票第 i 天的价格。
>
> 如果你最多只允许完成一笔交易（即买入和卖出一支股票），设计一个算法来计算你所能获取的最大利润。
>
> 注意你不能在买入股票前卖出股票。

<!--more-->

示例1：
```
输入: [7,1,5,3,6,4]
输出: 5
解释: 在第 2 天（股票价格 = 1）的时候买入，在第 5 天（股票价格 = 6）的时候卖出，最大利润 = 6-1 = 5 。
     注意利润不能是 7-1 = 6, 因为卖出价格需要大于买入价格。
```

示例2：
```
输入: [7,6,4,3,1]
输出: 0
解释: 在这种情况下, 没有交易完成, 所以最大利润为 0。
```

### 解答思路

#### 暴力法

暴力法的思路很简单：两层遍历，列举出所有可能的情况，然后求最大值。

这种方法的时间复杂度为 `O(n^2)`

```js
fuction maxProfit(prices) {
    let maxprofit = 0;
    for (let i = 0; i < prices.length - 1; i++) {
        for (let j = i + 1; j < prices.length; j++) {
            let profit = prices[j] - prices[i];
            if (profit > maxprofit)
                maxprofit = profit;
        }
    }
    return maxprofit;
}
```

#### 动态规划

动态规划的**思想**主要是两点：
1. 自底向上分解问题
2. 通过已得到的下层的解逐步转化成上层的解

对于这道题，我们可以在暴力法的基础上利用动态规划进行优化：
1. 利用一个表（数组）记录每一天卖出可以得到的最大利润
2. 该天的最大利润通过前几天的最大利润加上这两天的价差来得出

以上，我们就可以得出动态规划的解答。

遍历过程的解：

天 | 价格 | 卖出获得的最大利润
---|---|---
1 | 7 | 0
2 | 1 | 0
3 | 5 | 4
4 | 3 | 2
5 | 6 | 5
6 | 4 | 3

然而，我们还需要基于该题目的特征进行优化：
- 按照顺序来说，能获得利润的第一天肯定是当前的最大利润，如示例 1 的第 3 天
- 二层遍历只需找到前面最近的最大利润大于 0 的参考时间点即可，如示例 1 的第 4 天的利润只需参考第 3 天的利润

参考代码：
```js
function maxProfit(prices) {
    let profitArr = (new Array(prices.length)).fill(0);
    let max = 0;
    for (let i = 1; i < prices.length; i++) {
        for (let j = i-1; j >= 0; j--) {
            if (profitArr[j] > 0 || prices[i] > prices[j]) {
                const profit = profitArr[j] + prices[i] - prices[j];
                if (profit > 0) {
                    profitArr[i] = profit;
                    max = Math.max(max, profit);
                    break;
                }
            }
        }
    }
    return max;
}
```

以上解法的时间复杂度是：最优 `O(n)`，最差 `O(n^2)`。空间复杂度为 `O(n)`。

#### 最优解

我们知道：
- 遍历本是有顺序性，跟本题要求切合
- 在第 i 天卖出的情况下，只需前些天最低的价格即可求最大利润

所以，我们不需要记录每天卖出的最大利润，只需记录一下前些天的最小价格即可。然后，整个问题的解可从子问题解上求最大即可。

参考代码：
```js
function maxProfit(prices) {
    let minPrice = Number.MAX_SAFE_INTEGER;
    let max = 0;
    for (let i = 0; i < prices.length; i++) {
        minPrice = Math.min(minPrice, prices[i]);
        max = Math.max(max, prices[i] - minPrice);
    }
    return max;
}
```

此解的时间复杂度为 `O(n)`，空间复杂度为 `O(1)`。
