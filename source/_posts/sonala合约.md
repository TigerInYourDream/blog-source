---
title: sonala合约
date: 2024-06-12 20:00:49
tags:
  - 合约
  - solana
---

# solana合约学习

本文是对 solana先关问题介绍，主要用于记录solana合约的学习过程。因为现阶段还没有十分深入的学习 solana的细节，所以目标限定在 solana的简单合约编写，环境搭建，测试。

## 基础

因为是学习指南，所以会先强调学习的基础。本文的基础建立在会 rust基础上，明白 rust的语法，可以达到 rust编写简单代码的基础之上。因为 solana 合约是直接使用 rust编写的。如果不具备简单的 rust基础，请先学习 rust book，至少了解 rust的基本语法。

## solana环境

因为 solana有自己的介绍文档，不再重复介绍solana概念。下面主要讲剩余部分。

1. 开发环境
    1. 主要就是 rust环境，可以去 rust官网上直接安装 rust环境。因为 rust已经比较成熟，没有特别的问题，直接安装最新环境。
    2. 编辑器，因为是直接使用 rust开发solana 合约的，所以主流的 VSCODE Rustrover vim zed emacs都可以。选择自己喜欢的就好。
    3. solana cli工具。[https://solana.com/developers/guides/getstarted/local-rust-hello-world](https://solana.com/developers/guides/getstarted/local-rust-hello-world)
    4. cli工具是生成地址，链接 solana节点，部署合约的基础。后面会继续提到一些注意事项，请务必参考安装的的注意事项。
    5. anchor  anchor是 solana 的“框架”，可以去 anchor官网安装 solana框架。后面也有注意事项。
    6. 以上的套件理论上是全部需要的。如果你只是使用solana native开发，可以不使用 anchor。也就可以不用安装 anchor 套件。

## 环境安装中的特殊问题

1. 根据目前 2024年06月08日20:17:14 时间 solana 是 v1.18.15。 solana 本身并不是直接安装最新版本就好了。最新版本可能出现编译不过，获取有一些更加具体的字节超量的编译问题。这时候就需要回退到历史版本。可以看下面的链接。当然如果你非常幸运，安装之后完全没有问题就不必折腾。事实是，我安装了最新版之后一直无法通过编译，然后不得不安装下面的方案回退。
2. [https://www.notion.so/alvinvip/cd22ecfe315d4acbb83c68ca8a3d7b30?pvs=4#14fa26df7432402ebf18529fecf20e40](https://www.notion.so/cd22ecfe315d4acbb83c68ca8a3d7b30?pvs=21)
3. anchor也存在以上问题，最新版无法运行。这样采用上面的办法即可，直接退版本。
4. [https://book.anchor-lang.com/getting_started/installation.html](https://book.anchor-lang.com/getting_started/installation.html)
5. 注意查看版本关系 anchor 0.30需要使用最新的 solana v1.18.15（务必注意时间，后续升级必须兼顾 solana版本和 anchor版本）

### 测试问题

1. solana是使用 rust写的合约，完全可以使用 rust代码来测试。但是，务必记住，如果你使用 anchor的话，直接使用 TS测试。TS包提供了完整的测试环境和方法，非常方便。在 solana的世界中，使用 TS测试是常态。使用 rust测试反而是异类。应该还是 TS程序员更加普遍的原因，优先支持更流行的语言。
2. 所以在会 rust的基础上可以，快速学习一下 js语法，然后学一点 TS即可。
3. [https://www.youtube.com/watch?v=vDNw0FWL8zw&ab_channel=走歪的工程師James](https://www.youtube.com/watch?v=vDNw0FWL8zw&ab_channel=%E8%B5%B0%E6%AD%AA%E7%9A%84%E5%B7%A5%E7%A8%8B%E5%B8%ABJames)
4. 在 youtube上随意找到一个 js教学视频，大概两小时可以了解 js用法。然后再花 20 分钟学习一点 TS和 js的不同之处即可。所以没错，这个学习过程中包括两个半小时的 js/ts基础的学习。学习到可以写代码即可。
5. 如果一定要用 rust测试也没有问题

```jsx
anchor init —test-template rust <xxxxx>
```

1. 使用以上命令可以生成 带rust测试模板的 anchor 代码。
2. https://github.com/coral-xyz/anchor/pull/2805
3. 上面的 PR也是关于 rust测试的，可以看出来anchor对于 rust测试支持也是最近才有一定的进展。所以建议还是现学TS测试比较快。

### 节点

大部分时候节点使用不应该成为一个问题，但是 solana的 devnet似乎很不稳定，所以最好使用本地网络部署的和测试

 

```jsx
 solana-test-validator 
 
 solana-test-validator -r
```

上面的两个命令是启动本地节点和 重启本地节点。如果你在启动节点的时候 7 遇到问题可以考虑这个。主要的症状是再次重启，节点状态不对。

### 和同等类型合约的差别

众所周知，使用 rust编写的区块链还有 sui和 aptos。在 solana合约之前，我还学习了 move合约

[https://github.com/TigerInYourDream/letsmove](https://github.com/TigerInYourDream/letsmove)

上面是我参与 sui 合约的代码。sui的合约使用 move编写。和 anchor不一样，move的环境安装没有上面的特殊问题。直接安装最新就可以。move是一个简易版本的 rust，学习难度显著降低。

另外 sui的主要交互可以使用命令行实现，主要参数就是部署时刻生成的各种 hash id。可能对于后端程序员这这种方式更加直接。

但是 sui move目前支持的功能相对少一点。所以两种合约各有优缺点。

### solana的抽象层次

和所有的区块链编程模型一样 solana划分为下面的结构

![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/solana_example.png)

solana使用合约直接使用 rust编写。写好的合约可以直接部署到 solana的节点上。这个过程称之为发布合约。solana因为使用 rust，和其他区块链稍有不同，把编程部分成为 program。他也确实是个完备的 program。为了和其他区块链中的概念统一，也可以把它称为智能合约。

部署节点上的合约，就相当于给 solana节点增加了新的“接口”。可以调用 solana client sdk直接调用合约实现交互。最直接的使用 solana js sdk就可以实现前端网页与合约交互。使用 sdk与节点交互的这个应用就是 dapp。

和金融里面合约不一样，区块链世界的“合约”就是一段可以执行的代码。所以有的区块链也把自己称之为“互联网计算机”。能执行代码，也能被调用，的确是是一个“计算机”。

此外，让链上数据发生变化的操作叫做交易。无论是通过 dapps 或者 rust js 客户端或者其他方式和链上信息进行交互的过程都叫做交易。

### anchor和 solana的关系

在 solana链上实现编程主要有两种方法

1. native program 
2. anchor

[https://solana.com/developers/guides/getstarted/local-rust-hello-world](https://solana.com/developers/guides/getstarted/local-rust-hello-world) 

使用以上代码， 引入 solana-program crates就可以进行 native solana program。如果你仔细查看代码， 你会发现指令 Instration是个 u8数组，也就是说进行网路传输的数据，你需要在合约段解码u8，相应的你需要在客户端进行编码。没错，你还需要了解编解码和 rust的 layout 的细节。否则无法解析出正确的数据。

anchor在solana-program的基础上套了一层，最主要的就是解决数据编解码的问题。这个就是原生编码和 anchor 编码的差别。anchor 也是 solana官网推荐的写合约的方式。当然，如果你无畏 layout细节，native 合约也是可以的。

### 一些其他的推荐

可以使用 just工具，预先写好合约编译，发布和测试命令。然后使用just运行。生成自己的流水线，是我个人推荐的方式。如果有一些其他复杂的命令行，可以再花 20 分钟学习 amber。可以设计出一些比较复杂的合约部署流程。丰俭由人。

### 教学视频

[https://www.youtube.com/watch?v=3GHlk6vosQw&list=PL53JxaGwWUqCr3xm4qvqbgpJ4Xbs4lCs7&index=12&ab_channel=Josh'sDevBox](https://www.youtube.com/watch?v=3GHlk6vosQw&list=PL53JxaGwWUqCr3xm4qvqbgpJ4Xbs4lCs7&index=12&ab_channel=Josh%27sDevBox)

solana已经有较多的编程实践了，课程很多。可以看上面的视频进行学习。也是一个比较不错路径。
