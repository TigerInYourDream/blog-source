---
title: sqlite自增小知识
date: 2021-01-20 10:06:54
categories:
  - 技术笔记
tags:
  - 数据库
---

# Sqlite自增字段

起因：在使用数据库存储从区块链网络上取来的block_header时，block_header本身并不带自身的高度信息。不过取来的数据是经过筛选的，按照数据库存储的顺序就可以代表blockheader的高度。所以在数据库中增加一个id primiry key autoincrement 的自增主键。每次从数据库查询时获取id值来代表区块的高度。但后来重构，id被TEXT类型的逐渐替代，所以这个功能无法正常实现。所以产生以下疑问

## 在已经有TEXT类型的主键后，sqlite可以拥有别的自增字段吗?

不可以！在sqlite的文档FAQ中第一个问题（文末给出参考链接）就是关于如何设置自增字段的。在sqlite中自增约束AUTOINCREMENT只可以跟在PRIMARY KEY后面。把AUTOINCREMENT放在主键以外的地方是不可以的。或者再明确一点，要想在sqlite中拥有一个自增字段必须这样写

```sqlite
id INTEGER PRIMARY KEY AUTOINCREMENT,
```

要求id的类型必须是INTEGER。每次插入数据库的时候，不要插入id的数据，数据库会自动为我们的主键id实现自增。之前提到的情况：id已经是TEXT PRIMARY KEY的状态下，**无法**再拥有另一个自增字段了。

题外：在sqlite以外的数据库中是可以的。以mysql为例，mysql的AUTOINCREMENT是可以加在主键之外的地方的。一个表中，只允许有一个自增字段，而且在mysql中需要给主键以外的字段实现自增，**必须给该字段加上**unique约束。

注意点:

1. 在设定id INTEGER PRIMARY KEY，不加AUTOINCREMENT，只要不指定插入id的数据，id字段也可以实现自增。

## 在已经有TEXT类型的主键后，一定要有一个自增的字段来记录当前所在的行数怎么办？

sqlite数据库中自带一个字段叫做 rowid，rowid就是一个自增字段。我们查询的时候，直接查询rowid就可以知道当前行数。（但是sqlite有without rowid类型表，这种表不带rowid字段）。一旦我们在数据库中设定 id INTEGER PRIMARY KEY，id就相当于rowid的别名。在sqlite3中，rowid的大小为64-bit signed integer，大小范围为i64。rowid最大值为9223372036854775807。

## rowid的行为

rowid由数据库自行维护，只要用户不去主动干涉。rowid每行加一。当rowid超过以上的范围时刻，会在允许范围内随机找还没占用到的数字填充。当我们删除行之后，rowid所代表的数字是可以被复用的。如果所有数字确实用完之后数据库会抛出SQLITE_FULL error。

## rowid和序列

在sqlite数据库中，如果启用了AUTOINCREMENT，数据库会有一个内建的表叫做[sqlite_sequence](https://sqlite.org/fileformat2.html#seqtab)来记录rowid的变化。注意：这个序列表是可以正常操作的，比如插入数据，更新数据。修改的前提是用户要清楚自己操作对数据库有何影响。当数据库插入数据时，序列表就会关联的发生变化。因为序列表的存在，加了AUTOINCREMENT的数据库要稍微慢一点。且序列表由数据库创建和删除，不允许用户自行创建和删除。

其他注意事项：

```
ROWID, _ROWID_, OID都可以用来表示rowid
```

参考资料：

1. https://sqlite.org/faq.html#q1
2. https://sqlite.org/autoinc.html

