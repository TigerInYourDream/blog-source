---
title: 在M1上编译substrate
categories:
  - 技术笔记
tags:
  - 区块链
  - substrate
abbrlink: 31576
date: 2021-03-11 10:01:02
---

之前已经在x86的mac电脑上编译过substrate，按照官方指南上的操作就可以正常编译。但是在新款m1电脑上并没有编译通过，现在重新尝试在m1上编译substrate。

主要的准备过程参考如下文章

https://zhuanlan.zhihu.com/p/337224781

不过参考文章写于2020年12月16日，到现在（2021年3月10日）有部分状况已经发生了变化。针对和文章中不一样的状况稍作说明。

## RUST

rust环境现在可以直接支持m1。所以使用rustup脚本可以直接安装rust，不需要额外设置。安装完成之后使用

> rustup show

查看toolchain。则会发现是以aarch64开头的，原来的x86下面的tool-chain是

> stable-x86_64-apple-darwin (default)

注意差别。

## brew

mac上的包管理离不开brew，所以一定需要安装brew。brew现在也已经官方支持m1，不再需要像参考文章中的特殊设置，直接使用官方脚本安装即可。brew在mac下有两个目录，我们暂时只关心在m1下的原生文件目录。可以cd到一下目录查看

> ```bash
> /opt/homebrew
> ```

确保文件存在，如果你使用的是zsh，则在.zshrc中设置如下，如果你使用bash则在~/.bash_profile添加如下

```bash
export PATH="/opt/homebrew/bin/:$PATH"
```

## substrate 配套环境

安装好brew之后，你需要下面四个依赖

```bash
brew install -s cmake
brew install -s gcc
brew install protobuf
brew install -s llvm
```

依次安装即可。注意设置llvm的环境变量中。比如我使用zsh. 就在~/.zshrc中写入

```bash
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
```

以上安装注意看brew的提示。brew也会提示你设置以上环境变量。

每次写入环境变量记得source.

## 编译substrate

本文以官方教程为例

https://substrate.dev/docs/en/tutorials/create-your-first-substrate-chain/setup

我们使用2.0.1版本的substrate.截止目前（2020.3.10）substrate已经有3.0版本，但是本文以教程为准，使用2.01版本

在合适的目录克隆

```
git clone -b v2.0.1 --depth 1 https://github.com/substrate-developer-hub/substrate-node-template
```

进入到node-temple目录后，需要升级如下两个依赖库

```bash
cargo update -p fs-swap
cargo update -p ring
```

substrate还需要依赖rustrocksdb

```bash
$ cd ${anywhere}
$ git clone https://github.com/hdevalence/rust-rocksdb.git
$ cd rust-rocksdb
$ git submodule update --init --recursive
```

我和参考文章一样把rust-rocksdb放在了如下位置

> /opt/homebrew/opt/

然后去修改~/.cargo目录下的config，注意默认情况下config文件是不存在的，首次设置之前你需要自己创建该文件。

然后在config文件中写入如下

```bash
paths = ["/opt/homebrew/opt/rust-rocksdb/"]
```

之所以修改是因为原本依赖中的三个问题。

> 1. fs-swap原本的依赖在m1下无法编译，新版本解决了这个问题，所以需要使用cargo update升级
> 2. ring同理
> 3. rust-rocksdb也无法在m1下编译，所以感谢hdevalence，自己fork出来修改了问题。我们依赖这个fork出来的rocksdb

说明：在.cargp/config中使用这种path依赖并非最优选择，在项目本身中使用patch是更好的做法，稍后编译中会出现相应的警告提示这一点。关于如何使用patch请参考《cargo book》，本文不做讨论。此外提示，对于substrate这种以workspace组织起来的项目，patch信息写在根目录下面的Cargo.toml中。

接下来编译还会出现一个问题，报错的形式如下

```
error[E0609]: no field `__rip` on type `__darwin_arm_thread_state64`
   --> crates/runtime/src/traphandlers.rs:169:44
    |
169 |                     (*cx.uc_mcontext).__ss.__rip as *const u8
    |                                            ^^^^^ unknown field
    |
    = note: available fields are: `__x`, `__fp`, `__lr`, `__sp`, `__pc` ... and 2 others
```

关于这个错，我们可以参考

https://github.com/bytecodealliance/wasmtime/issues/2575

讨论中已经提到了这个问题的解决办法，所以我们直接把__ rip换成__ pc即可。提供一个最快捷的修改办法

> 直接进入到错误提示的源码处，直接修改依赖库的源码，把_ _ rip改成 _ _ pc。
>
> 注意：这么改是为了快捷，绝非良策。因为rust库的构建依赖cargo管理，我们直接去修改了库的源码，如果使用cargo update，或者其他触发了Cargo.lock变动的操作，依然可能编译不过。 好的办法还是fork下来使用patch依赖。

所有准备工作做完之后就可以

```
cargo build --release
```

大概七分钟左右就可以编译完成。比原本的x86 mac快很多。

## 本文的编译的环境汇总

1. Rustc 使用1.50.0版本，可以使用rustup show查看
2. Substrat-node-template 使用v2.0.1版本
3. 硬件环境为 m1 mac
4. 操作系统 macOS Big Sur 11.2.3

## 一些建议

经常看到讨论substrate编译不过问题的。经常面对这种问题可以做一个详细的文档来记录这些，文档中可以包含以下内容

> 1. rust tool-chain的版本
> 2. 可以编译操作系统信息 比如linux某版本  windows某版本，mac有m1版本和x86版本也需要额外说明
> 3. 需要额外安装的依赖，比如这里提到的llvm protobuf
> 4. 基于某个substrate版本开发的  比如本文基于v2.0.1
> 5. 基于当前版本substrate需要做的某些调整，比如本文中提到的ring fs-swap升级 wasmtime的修改等。
> 6. 如果版本升级了，需要配套更新以上这一套信息（这里的版本升级包含rust升级和substrate升级）
> 7. 如果有必要可在项目下专门建立一个patch文件，来管理需要patch的包。

相信做到以上的7点，就不用反复的去解决编译不通过的问题。

本文完。