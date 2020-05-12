---
title: 如何给过长数组实现Debug
categories:
  - 技术笔记
tags:
  - rust
abbrlink: 64038
date: 2019-11-26 18:34:18
---

在rust中，我们可以很方便的用Derive给结构体实现Debug宏（是编译器自动实现的），但是编译器给数组实现的Debug只有长度在32以下的，要是超过32位就得自己实现了。所以出现了本文的问题

#### 如何给过长数组手动实现Debug Trait。

一番尝试之后，发现可以这样

```rust
use std::fmt;

struct Array<T> {
    data: [T; 1024]
}

impl<T: fmt::Debug> fmt::Debug for Array<T> {
    fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        self.data[..].fmt(formatter)
    }
}

fn main() {
    let array = Array { data: [0u8; 1024] };
    println!("{:?}", array);
}

```

注意：如果直接考虑给[T; 1024]实现Debug是不行的，因为违反了孤儿规则。Debug Tarit和[T;1204]都没有在本crate中定义。