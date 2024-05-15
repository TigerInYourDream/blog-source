---
title: REVM代码阅读 01
date: 2024-05-15 14:51:16
tags: -evm
---

# REVM代码阅读 01

经过一些时间的准备，现在进行 REVM代码的阅读

### 准备环节

这些准备主要包括一下的方面

1. 速览 《精通以太坊》，有一个全局的认识
2. https://github.com/WTFAcademy/WTF-Solidity 通过这些资料来了解 solidity的语法。我的标准是学习完上面的课程并且完成习题，通过认证。
3. [https://www.wtf.academy/docs/evm-opcodes-101][1] 通过这些资料来学习以太坊的操作码 OPCODE， 因为不会 python， 所以使用 rust实现了其中其中的逻辑。可以参考这个链接https://github.com/TigerInYourDream/naive\_evm 。主要需要跑通其中的用例（执行其中的 bytecode）。（至少做完 101 和 102）

做出了以上的准备之后，可以对以太坊虚拟机有一个整体性认识。其中改的代码可以参考上面的链接阅读。

### 总体概览

经过以上的准备，对以太坊虚拟机有了一个感性的认识。从最简单的模型，以太坊虚拟机就是一个栈的数据结构，每次把b solidit编译成对应的 bytecode,然后拆分成一个又一个的 op code。把 op code按照栈的方式一次执行就完成了“虚拟机”的工作。

下面图来自于 WFT Academy的 op code 101教程，从高层次展示了以太坊虚拟机的结构

![https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/evm\_overview.png][image-1]

### 核心概念概览

1. STACK 栈
	以太坊虚拟机的核心概念就是一个栈。这里假设任何阅读本文的人都最基本的计算机知识。以太坊的栈每个元素长度为 256位（32bytes）。最大深度 1024。单次操作最多包含栈顶的 16个元素。超过最大元素限制会出现 “Stack too deep” 错误。
2. MEMORY
	易失性存储，理解为一个动态数组。支持以 8 为或者 256 位写入，以 256 位读取。
3. Storage
	区别于 memory，Storage为持久化存储。简单理解存储为一个键值对HashMap。因为计算机实际上的存储只有数组。实际上的存储是目标都是如何高效生成 key,高效查找 value。区块链存储是一个比较复杂的话题，超过了文章的讨论范畴。
	对于以太坊的存储，键和值都是 256bit的数据。支持以 256 bit的读和写。他的数据是存储在链上的，持久化存在的。存储数据是一个比较昂贵的操作，读和取都需要消耗 gas费用。在需要阅读的 revm代码中，它借助 ethers-provider存储，自己并不直接实现存储的部分。
4. GAS
	gas就是燃料费。以太坊用燃料费来衡量合约的消耗。revm中有很多代码是用来计算 gas费用的。一笔交易的 GAS总消耗是所有 OP\_CODE gas费用之和。注意你需要合理的估算 gas费用。如果 gas不足，合约会在 gas消耗完之后停止合约执行，gas费用不会返回。优化gas消耗是合约优化的重要方向。

### 以太坊执行模型

以太坊执行概览图如下图所示，这个也是参考了WTF

![][image-2]

当交易准备执行的时候，主要执行下面的步骤

1. 初始化执行环境，并且加载字节码。执行环境被称为 ENV在后续解读 REVM源码的部分会看到。
2. 字节码会被转化为 opcodes，逐一执行。每个 Opcodes代码一种固定的操作。这个可以参考以太坊 Opcodes章节
3. 执行一个opcodes,对应需要相当量的 gas费用。如果 gas消耗完毕，则合约中断执行，在 gas消耗费用以外的数据逐一回滚。
4. 执行完成后，所有数据会在区块链上记录。包括 gas消耗和日志信息。(即Solidity中的 Events)

从顶层理解以太坊虚拟机的结构后，可以参考下面的代码

[https://github.com/TigerInYourDream/naive\_evm][2]

这个库是根据以太坊虚拟机的最基本原理实现的以太坊Opcodes操作实例，相当于参考 WTF academic 中的代码，但是把它实现为 RUST。 原文是 python实现的。

在以上的执行模型中，相当于展示了 Opcodes每个操作的具体意义。

2024-05-15 14:56:58

[1]:	https://www.wtf.academy/docs/evm-opcodes-101
[2]:	https://github.com/TigerInYourDream/naive_evm

[image-1]:	https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/evm_overview.png
[image-2]:	https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/evm_exec.png