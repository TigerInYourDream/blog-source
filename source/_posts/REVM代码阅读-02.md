---
title: REVM代码阅读 02
tags:
  - eve
abbrlink: 44402
date: 2024-05-28 20:23:51
---

# REVM代码阅读 02

## 前文介绍

在 01章节，对阅读 revm做了一些预先的准备工作，主要包括了解solidity语言，学习 OPCODES以及自顶向下了解 evm的基本结构三部分。其中第三部分最好大致实现征战虚拟机栈的运行过程加深理解。现在开始阅读 revm代码。阅读代码的过程比较枯燥，请保持耐心。

针对单独实现的 evm不在少数，使用 rust编写的 evm也不是唯一的。有下面的两个

[https://github.com/rust-ethereum/evm](https://github.com/rust-ethereum/evm)

以上是 rust-ethereum名下的 evm项目，他是 parity名下的项目，在项目中提到 polkdot项目就使用该虚拟机。

另外一个就是我们看的 evm revm

[https://github.com/bluealloy/revm](https://github.com/bluealloy/revm)

也有众多的以太坊生态项目使用该虚拟机。该项目拥有一本 books来介绍虚拟机的设计思路。在初步阅读代码之前，我们先阅读文档来了解 revm的整体设计思路。

[https://bluealloy.github.io/revm/](https://bluealloy.github.io/revm/)

revm是一个存粹的以太坊运行环境，没有任何网络以及共识的部分，也有降低简化阅读难度。

## Revm Books

### Evm

根据 revm books的介绍，revm主要分四部分

1. revm: revm核心代码。
2. interpreter: 翻译为解释器。执行带有指令的循环。在上一节中已经提到，revm就是一个栈数据结构，依次弹出栈中的数据和指令（opcodes）进行和执行。
3. primitives: 以太坊的原始数据类型。比如U256。是对于 rust数据类型的包装。
4. precompile: 以太坊虚拟机预编译。在执行之前做一些数据的检查。

每个 crates内部都有也有很多细分模块，这里只是介绍 revm中主要的部分。

1. EVM部分。evm包含两大部分 Context和 handler. Context翻译为上下文，是一种编写二进制应用程序的常见方法，主要包含执行所需的状态。Handler包含作为执行逻辑的函数。Context分为两种具体的 EvmContext和 external context。external context翻译为外部 context。只要是为了外部调用执行的 Hook钩子。EvmContext为内部 Context，有database，environment，journaled state，precompiles四部分。
2. 运行时 Runtime。包含从 handler中调用函数。参考以下示意图

![https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/evm_loop.png](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/evm_loop.png)

所有的函数按照以上的四个类别进行分组，且按照对应的顺序运行。其中 Execution阶段包含两个循环。 call loop和 interpreter loop。

第一个循环是调用循环，循环中的每一步被称为 Frame，帧。Frame生成 Interpreter loop。Interpreter 负责遍历执行字节码操作（opcodes）。相当于在 call loop中嵌套 Interpreter loop。Interpreter 执行的结果是 InterpreterAction。InterpreterAction 相当于一个枚举，分别指示 Interpreter是否执行完成。传导到“父”级别 Frame中。

其中 Evm是负责运行的模块，在 Evm模块“之前”，有一个 EvmBuilder，会“设置”Evm需要执行的功能。Evmbuilder相当于一个“菜单”。

### [**Interpreter**](https://bluealloy.github.io/revm/crates/interpreter.html#interpreter)

evm是最核心的模块，也是程序的“启动点”。在上一小节中介绍的 evm中会开启两个两个循环，在  call loop中会嵌套执行 Interpreter循环。解释器循环直接涉及以太坊字节码操作，解释器直接充当事件循环逐步执行操作码。它设置 gas计算，合约本身，内存，栈堆操作，且返回执行结果。

Interprete'r crates中的 gas和 mememory简单介绍就是gas费计算，以太坊内存操作。大致介绍下其中的Host 部分：

1. Host是一个 trait
2. 因为 EVM操作是需要一定“链上信息的”，所以 Host中包含一些链上信息
    1. env 包含当前区块和交易信息
    2. load_account: 查询给定以太坊账户的信息
    3. block_hash：检索给定区块号的哈希信息
    4. balance code code_hash …  用于检索给定账号的余额 代码 代码 hash之类的信息
    5. selfdestruct 
3. Host部分维护了一个线上数据获取的统一接口，可以使得虚拟机链接到不同的以太坊网络，比如 mainnet, 测试网等。所以这部分被命名为“主机”。

### interpreter_action

interpreter action主要定义了一些解释器执行过程中的数据结构。有 strcuct和 enum主要包含了evm操作的方方面面。比如调用和创建输入，调用上下文（context)，价值转移（以太坊合约合约很多都是围绕转账展开的），以及自毁操作

其他结构略过。以上大致分散的介绍了revm中的前两部分。

待续。。

2024年05月28日20:23:10
