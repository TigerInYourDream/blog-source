---
title: Mac上安装和使用PostgreSQL的方法
categories:
  - 技术笔记
tags:
  - 技术
  - PostgreSQL
abbrlink: 31755
date: 2019-03-27 16:21:13
---

最近需要使用actix-web来搭建一个web程序，这篇文章是关于搭建web程序的准备工作，
<!--more-->
如何在Mac上安装PostgreSQL
1. 因为本机上已经安装了homebrew 故而使用home brew
    `brew install postgresql`

2. 安装的位置如下

  `/usr/local/var/postgres`

3. 安装成功后已经可以使用命令行

  `pg_ctl -V`

  来查看psql的版本，正确显示版本说明已经安装成功了。

4. 在mac上安装PostgreSQL,需要开启psql的服务，仔细观察安装PostgreSQL的提示，brew已经提示你如何开启服务了。                                         

  `brew services start postgresql`

  或者使用

  if you don't want/need a background service you can just run:

  `pg_ctl -D /usr/local/var/postgres start`

  对应的使用如下命令来停止PostgreSQL的服务

  `brew services stop postgresql`

  也可以根据直接使用如下命令来查看brew启动的服务，不过属于brew的操作，和本文无关

  `brew services list`

5. 注意，很多文章都说需要在bash 或者zsh中添加环境变量，可能因为是版本的原因，截止我发文时间，是不需要添加envpath的。

6. 使用

  `creatdb` 创建出一个以当前系统用户名为数据库用户名的数据库

7. 使用 

  `psql`

  这时进入数据库控制台，相当于系统用户进入同名的数据库中,终端中会显示

  `xxxx = #`

  其中 `xxxx` 代表当前系统用户名

8. **以下操作psql下执行**

9. 为当前数据库设置一个密码,默认是没有密码的

  `\password `，

  按提示输入锁设置的密码就行,注意没有密码似乎不可以授权。

  在此之前可以使用 `\du`来查看当前的所有用户

10. 创建一个数据库用户 **注意以下下三条命令都需要;**

  `CREATE USER dbuser WITH PASSWORD 'password;'`

  创建成功后会出现

  `CREATE ROLE`

11. 为数据库用户建立一个数据库 这里创建的数据库是exampledb 数据库的拥有者是dbuser

   `CREATE DATABASE exampledb OWNER dbuser;`

   成功后依然有提示

12. 将exampledb数据库的所有权限都赋予dbuser，否则dbuser只能登录控制台，没有任何数据库操作权限。

   `GRANT ALL PRIVILEGES ON DATABASE exampledb to dbuser;`

   成功后也有提示。吐槽一下，这一点也不符合linux哲学，成功后什么也不发生，错误有提示才是真正的liux风格！

13. \q 退出

14. 然后使用新用户名 密码 登录 

   `psql -U dbuser -d exampledb -h 127.0.0.1 -p 5432`

15. 接下来可以尝试创建表格 插入数据等工作。之后为SQL操作。

16. 除了以上的命令行方式，也可以使用官方提供的pgadmin工具，或者DataGrid 工具;这些不包含在本文中。





