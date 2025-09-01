---
title: diesel使用小要点
categories:
  - 技术笔记
tags:
  - rust
abbrlink: 35993
date: 2021-10-14 18:39:14
---

# diesel使用的一些小知识点

最近因为使用diesel，大致看了diesel的文档同时结合自己两天内写代码的经验，总结出下面几条要点，作为参考。严格来说，这些知识点比较琐碎不能够成为一篇文章，但是想到可以为自己以后使用diesel作参考还是写出来。

1. 设置好.env之后 diesel setup   是创建数据库的 

2. diesel migration generate create_posts   最后一个参数是创建migration的文件夹名的 它会生成一个带时间的migration文件  里面有个up和down的sql up 里面负责创建数据库表的  down 里面负责撤回车操作的 

3. up 和 down 里面的sql要自己创建 

4. diesel migration run  执行migration里面的up.sql的操作的 确切的说就是建表 5. diesel migration redo 执行migration里面的down.sql的操作 确切的拉说是删除表 

5. 注意了 setup是会创建数据库和直接运行migration run中的建表数据的 但是如果数据库存在是不会运行的。如果在  migration中添加，后续这个也是不会运行的 

6. 这一步进行之后schema文件也会生成。这个文件是可以改的 ，但是不建议改 

7. 如果升级数据库，请使用新的migration文件 

8. 注意使用extern crate diesel 和#[marco use],不然schema下的东西又是找不到的

	以上的条目中需要补充的还有如下

	> 本来以为在rust2018版本以后，就完全不使用extern crate了。但是事实证明还是需要extern crate diesel和#[marco_use]的，不然会有很多东西找不到

	> 使用diesel尽量引入prelude::*  虽然我不喜欢这样引入，但是自己精确引入会很麻烦

	> 一定要注意schema文件

## 如果使用只是使用diesel查询和写入如何简化代码

这个问题会显的很奇怪，因为作为一个ORM，本来就是辅助我们进行增删改查的。其实我们看了diesel的官方指引之后就会觉得这个问题很合理。重新表述如下

> 根据diesel的官方指引，我们是用建立连接，建立数据库，设计表这几个步骤一路走下来的。实际上，大多数时候，数据表并不是我们建立的。我们只需要使用diesel的库，连接数据库CRUD即可。这种情况下，如何简化操作呢？

根据我的尝试大致需要如下

1. 引入库，这个是必须的

2. 设置sql路径，这个是必须的

3. 无需diesel setup因为我们不需要建立数据库，数据库是存在的

4. 无需diesle migration run 因为表也不是我们建立的。

5. 没有建表，没运行diesel migration run，则diesel不会为我们自动建立schema.rs文件，也不会在schema.rs中生成table宏的语法。所以我们需要手动去建立schema.rs的文件，src/schema.rs。就是必须建立的在src路径下面。这样才不会出错。然后我们在schema.rs中手动写入 table!宏。这样才可以正常使用。

6. 以上的步骤是可以正常使用的，也是文件最少的情况。还有下面的情况补充

	> 如果我们运行了diesel set 如果数据库存在，是不会建立数据库的。会产生一个migrations文件。一个和Cargo.toml同级别的diesel.toml文件，里面配置了schema.rs文件的位置。  所以上一步中如果不运行diesel set，需要我们手动把schema文件放在指定的位置。
	>
	> 同时，因为我们 不建表，所以不运行diesel migration run。schema里面是空的，为了正确使用orm的方便特性，我们得去手动补全这个文件，自己写table!宏。当然这个很容易。看example即可

	一些零碎的知识，其他的正常使用参考文档即可。这个算是在文档之外的补充备查！