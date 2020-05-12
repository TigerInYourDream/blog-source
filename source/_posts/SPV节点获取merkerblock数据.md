---
title: SPV节点获取merkerblock数据
categories:
  - 技术笔记
tags:
  - 区块链
  - 比特币
  - SPV节点
  - 比特币网络协议
abbrlink: 2926
date: 2019-12-10 14:54:22
---

在之前的文章中提到了SPV节点，一直说要写文章说明是什么是比特币SPV节点。网上有很多文章来描述这个问题，我之前也写过相关的文章，有兴趣的话可以回去查阅相关问题。简单来说，SPV**节点最主要的特点就是：只存储头信息（BlockHeader）。**所以他做到了存储数据规模大幅减少，只有完整数据的千分之一的水平。所以SPV节点适合在存储有限的设备上运行，比如手机客户端。但是本文的重点不是重复讲述SPV节点的概念的，而是换一个角度，从比特币网络协议入手，描述如何从全节点下载SPV所需的数据到节点上（SPV节点上）。这个所需的的信息，就是merkerblock。

本文的关键字是："SPV节点"，"比特币网络协议"，"BIP47"

## 交易的基本问题

在探讨如何和比特币网络进行信息交互之前先解释一个基本问题

### 实现比特币交易的形式有哪些？

[![QBiCUU.md.png](https://s2.ax1x.com/2019/12/10/QBiCUU.md.png)](https://imgse.com/i/QBiCUU)

虽然如此描述这个问题并不准确，但我还是按照自己的理解去解答这个问题，同时参照以上的图片来辅助说明。实现交易的形式有两类

1. 借助于比特币全节点
2. 借助于比特币的SPV节点

对于1，很明确。比特全节点有区块链完整的信息。获取任何交易信息，发起交易和广播不在话下。

重点需要解释的是2。借助于比特币的SPV节点。之前的文章提到过，SPV节点需要根据merkel root来验证交易的存在（注意用词，是验证交易的存在，反之是不行的）。那把这个问题提前一步，变成**SPV节点如何获取自己所需的merkle root数据**，这个图就是来描述这个问题的

> 一个SPV的体系如图所示，wallet连接一个SPV的节点，因为SPV节点不存在完整的数据，所以SPV必然连接其他的完整的节点以获取自己所需要的数据。节点Peers 指代的就是其他的Full Node。
>
> 实际情况中，如果要实现一个用户意义上的钱包（这个意义指：用户用这样一个App就可以实现比特币交易）wallet 和 SPV节点必然紧密相连。这里为了说明情况，所以特意分开。SPV节点和其他的Full Node之间是建立P2P网络的，他们直接交互就需要借助**比特币网络协议**。
>
> 本文假定SPV Node已经发现到了其他的Full Node(指已经知道了其他节点的IP)，节点发现和建立连接也是比特币网络协议中的专门话题，本文为了简化，暂不对其进行探讨。以后有机会再出一篇文章。当节点建立连接之后，SPV节点将向节点发送LoadFilter 消息，这条消息会设置和布隆过滤器有关的参数，比如filter，需要的的Hash Function个数等。Full Node会根据设置调整自己的布隆过滤器。接下来，SPV节点发送getdata消息给Full Node。因为第一次设置了布隆过滤器，所以全节点会利用布隆过滤器过滤掉无关信息，把SPV感兴趣的信息发送回来。这样就形成了一次完整的信息交互。

以上的描述中，需要明确一个小的问题

**Bloom Filtter在哪里？**

> Bloom Filtter在全节点上。一个支持布隆过滤器的节点，需要自己实现和Bloom Filtter 有关的方法。这样它就可以根据其他节点回传回来的loadfiltter 消息来设置。等到SPV节点需要getdata的时刻，利用之前已经设置好的Bloom filtter来过滤信息。发送merker root回去。

以上的内容，希望参考bip47的文档来理解

## 如何从比特币P2P网络中获取需要的数据

以上的内容介绍过之后，其实其实如何从比特币P2P网络中获取信息就已经说明了，不过为了文章的完整性，按照之前的惯例列出步骤。以下步骤假定已经确定对等节点的ip，且我们需要的数据为 merkerblock

1. SPV节点向Full Node发送 version 消息
2. 等待对等节点发送 verack 消息之后，SPV节点向Full Node发送 verack 消息
3. SPV节点发送 loadfilter 消息给Full Node
4. SPV节点发送 getdata 消息给Full Node
5. Full Node 回传 merkerblock 消息给SPV节点

其中前两个节点为握手的过程，必须有前两个步骤才可以正常的发送消息。比特币网络信息的交互全部依赖这种Message的传递。至于消息具体该怎么样请参考比特币网络协议的官方wiki和bitcoin-refrence。因为实际发送的数据和比特币网络协议wiki数据有出入，所以这两份材料要对照进行。另外比特币节点之间建立的是TCP链接。如果需要自己写代码的话，可以使用tokios这样的库（parity-bitcoin也借助这个库）。因为rust写起来相对麻烦，下面给出一个python的实例，体现这个过程

```python
from time import sleep
from hashlib import sha256
import struct
import sys

network_string = "f9beb4d9".decode("hex")  # Mainnet

def send(msg,payload):
    ## Command is ASCII text, null padded to 12 bytes
    command = msg + ( ( 12 - len(msg) ) * "\00" )

    ## Payload length is a uint32_t
    payload_raw = payload.decode("hex")
    payload_len = struct.pack("I", len(payload_raw))

    ## Checksum is first 4 bytes of SHA256(SHA256(<payload>))
    checksum = sha256(sha256(payload_raw).digest()).digest()[:4]

    sys.stdout.write(
        network_string
        + command
        + payload_len
        + checksum
        + payload_raw
    )
    sys.stdout.flush()

## Create a version message
send("version",
      "71110100" # ........................ Protocol Version: 70001
    + "0000000000000000" # ................ Services: Headers Only (SPV)
    + "c6925e5400000000" # ................ Time: 1415484102
    + "00000000000000000000000000000000"
    + "0000ffff7f000001208d" # ............ Receiver IP Address/Port
    + "00000000000000000000000000000000"
    + "0000ffff7f000001208d" # ............ Sender IP Address/Port
    + "0000000000000000" # ................ Nonce (not used here)
    + "1b" # .............................. Bytes in version string
    + "2f426974636f696e2e6f726720457861"
    + "6d706c653a302e392e332f" # .......... Version string
    + "93050500" # ........................ Starting block height: 329107
    + "00" # .............................. Relay transactions: false
)

sleep(1)
send("verack", "")

send("filterload",
      "02"  # ........ Filter bytes: 2
    + "b50f" # ....... Filter: 1010 1101 1111 0000
    + "0b000000" # ... nHashFuncs: 11
    + "00000000" # ... nTweak: 0/none
    + "00" # ......... nFlags: BLOOM_UPDATE_NONE
)

send("getdata",
      "01" # ................................. Number of inventories: 1
    + "03000000" # ........................... Inventory type: filtered block
    + "a4deb66c0d726b0aefb03ed51be407fb"
    + "ad7331c6e8f9eef231b7000000000000" # ... Block header hash
)
```

简单说明，网络的协议中的数据为hex小端编码。消息遵循的形式为messageHeader+payload。其中payload为具体消息的形式。比特币网络协议中的任何消息都遵循这个格式。

```
python get-merkle.py | nc localhost 8333 | hd
```

按以上格式运行即可。（假定节点搭建在本地，采用默认端口）。nc为netcat，hd为hexdump工具。

给出参考的资料

https://en.bitcoin.it/wiki/Protocol_documentation#filterload.2C_filteradd.2C_filterclear.2C_merkleblock

https://bitcoin.org/en/developer-reference#message-headers


