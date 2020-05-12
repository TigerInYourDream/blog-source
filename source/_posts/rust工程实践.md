---
title: rust工程实践
categories:
  - 技术笔记
tags:
  - rust
  - 笔记
abbrlink: 10047
date: 2020-02-16 21:22:27
---

# rust工程实践

本文是rust的实践记录，主要用来记录rust写工程代码，和在tikv的talent-plan中学习到的代码常识。这里列出的是比较重要，但是不足以写一篇文章来讨论的。长期更新。以后考虑加个目录方便查询。

1. 在写lib的时候，直接建立（在src下）bin文件夹，bin文件下的东西无需在lib.rs中声明就可以使用。且bin文件夹下的rust文件无论怎样命名，在文件中只要有fn main()就可以直接运行。也无需在Cargo.toml文件中进行特殊声明。在murmel和talent-plan中已经证明这一点。
2. 想要进行测试，请在src的同级目录下建立一个tests文件夹（注意拼写，必须是tests）。然后就可以使用cargo test命令。
3. [dev-dependencies] 适用于tests example benchmarks。正式构建的时候不会用到这个
4. 注重测试，因为测试定义了什么是正确行为。所以阅读源码也要看测试
5. Re-export技巧。假定我们有一个lib kvs。目录为kvs/src/lib.rs  在lib中定义了mod kv。另有文件夹kvs/src/kv.rs。（该文件中定义KvStore struct）如何实现使用kvs::KvStore即可正确定位。（不做特殊处理，我们应该使用kvs::kv::KvStore）。**正确做法是在lib中使用pub use KvStore。**这种技巧叫做Re-export。导入上一级即可。（各种无法正确引入，或者需要简化路径的，全部考虑这个方法）。理论基础可参阅《深入浅出rust》的使用设施/模块管理章节。