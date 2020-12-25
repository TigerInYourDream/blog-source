---
title: 多线程原语ConVar
date: 2020-12-24 16:33:46
categories:
  - 技术笔记
tags:
  - rust
  - 多线程
---

# 多线程原语CondVar

多线程下的原语，除了我们常用的锁，还有另外一类用于同步的原语叫做“屏障”，“条件变量”(在rust或者cpp中)。在其他语言中也有类似的概念，叫做栅栏，闭锁，屏障，信号量等。他们具有相同的意义。

在介绍条件变量之前，先介绍屏障（Barrier）。屏障相当于一堵带门的墙，使用wait方法，在某个点阻塞全部进入临界区的线程。条件变量（Condition Variable）和屏障的语义类似，但它不是阻塞全部线程，而是在**满足某些特定条件之前**阻塞某一个得到互斥锁的线程。

单纯讲条件变量的意义并不直观。换种描述

> 条件变量可以在我们达到某种条件之前阻塞线程，我们利用此特性可以对线程进行同步。或者说做到按照某种条件，在多个线程中达到按照**特定顺序执行**的目的。

为此我们设计如下下面流程。为此流程写一段代码，来体会条件变量的作用

> 我们启动三个线程，t1，t2，t3。分别执行任务T1，T2，T3。现在要求：T2必须等待T1和T3完成之后再执行

```rust
use parking_lot::{Mutex, Condvar};
use std::sync::Arc;
use std::thread;
use std::thread::sleep;
use std::time::Duration;


pub fn main() {
    let pair = Arc::new((Mutex::new(0),
                         Condvar::new()));
    let pair2 = pair.clone();
    let pair3 = pair.clone();


    let t1 = thread::Builder::new()
        .name("T1".to_string())
        .spawn(move ||
            {
                sleep(Duration::from_secs(4));
                println!("I'm working in T1, step 1");
                let &(ref lock, ref cvar) = &*pair2;
                let mut started = lock.lock();
                *started += 2;
                cvar.notify_one();
            }
        )
        .unwrap();

    let t2 = thread::Builder::new()
        .name("T2".to_string())
        .spawn(move ||
            {
                println!("I'm working in T2, start");
                let &(ref lock, ref cvar) = &*pair;
                let mut notify = lock.lock();

                while *notify < 5 {
                    cvar.wait(&mut notify);
                }
                println!("I'm working in T2, final");
            }
        )
        .unwrap();

    let t3 = thread::Builder::new()
        .name("T3".to_string())
        .spawn(move ||
            {
                sleep(Duration::from_secs(3));
                println!("I'm working in T3, step 2");
                let &(ref lock, ref cvar) = &*pair3;
                let mut started = lock.lock();
                *started += 3;
                cvar.notify_one();
            }
        )
        .unwrap();

    t1.join().unwrap();
    t2.join().unwrap();
    t3.join().unwrap();
}
```

以上代码可以在 [这个链接](https://play.rust-lang.org/?version=stable&mode=debug&edition=2018&gist=31292aa4c8c86b93f4111597679329e2) 下在playground运行。

上面的代码需要注意的点如下

1. CondVar需要和锁一起使用，在运行中每个条件变量每次只可以和一个互斥体一起使用。
2. 这里使用了parking_lot中的CondVar和Mutex，使用标准库中的条件变量和锁也是一样的效果。
3. 设计中，在锁中持有了一个数字类型。当锁中的数字（也就是我们的“变量”）小于5，我们使用wait阻塞住t2。我们在t1完成时，把数字加二，在t3完成后，我们把数字加三。
4. 注意，每次更改变量后要使用通知。
5. 一般情况下，我们可以设计更复杂的变量和阻塞条件来达到更复杂的同步效果

特别注意的是

> notify_one()只会通知线程一次，也就是说，如果我们有多个线程被阻塞住，notify_one会被一个阻塞地方消耗。不会传播到另一个阻塞的临界区中
>
> notify_all()会通知所有阻塞区。

所以使用的时候需要特别注意两种通知不同的使用场景，避免造成阻塞。

在CondVar中还有对应的wait_for。可以设置TimeOut，避免造成永久的阻塞。

