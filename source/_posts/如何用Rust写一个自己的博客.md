---
title: 如何用Rust写一个自己的博客
categories:
  - 技术笔记
tags:
  - Rust
  - actix_web
abbrlink: 44906
date: 2019-04-06 08:53:40
---

最近给自己定下一个任务，用rust写一个可以运行的项目，最终定下的任务就如标题所示，搭建一个可以运行的博客，具备基本的登录功能，可以对自己的文章进行增删改查功能。目标定下，接下来开始行动。代码在此

Actix_blog	https://github.com/TigerInYourDream/actix_blog_example

#### 选定框架
​	搭建博客自然不可能能徒手写一个，初步定下使用Rust的web框架actix(其实还有另一个方案Rocket)。工欲善其事必先利其器，先阅读actix_web的基本资料了解actix_web的使用方式。再快速阅读玩actix_web的文档后，发现了问题。因为本人没有web开发的相关经历，不理解web项目的组织方式，很多术语都看不懂，所以开发中的第一个难题就出现了：不理解web项目的组织方式，无法开始web项目的开发。既然基础薄弱无法开始，那么去了解web项目的组织方式就是当务之急。actix_web的文档本身可以说是有些过于简单，无法帮我达成这一目的。这个时候怎么办呢？多交流！和朋友的交流中得到一个信息，或许可以通过阅读

[Ruby On Rails]: https://ruby-china.github.io/rails-guides/getting_started.htm

文档达到理解web项目的组织方式。（说明：本人并不会ruby）所以直接阅读rails文档。通过阅读rails文档，得到以下结论：

> web项目基本上是典型的mvc模式，v = view.是视图层。主要用于呈现界面。m = modle 是数据层，主要用户储存数据，是用db或者orm就在这一层，c是衔接v和m的控制层，web框架的主要作用就是充当c层。
>
> 把actix_web和rails的概念对应起来，可以这么说。controller作为控制层是为了粘合其他部分的。在代码中的api文件夹里的代码就是c层。handle函数则是具体处理对应逻辑的函数，相当于rails里面的Action。模板很好理解，就是相当于rails里面的erb文件。(也就是c)。router这个术语就是给不同的网络请求分配对应的handler(Action)函数的。至于中间件middleware,则是夹在用户请求和响应之间的功能，名副其实的中间，可以做到加载特定参数或者写log等一下功能。

到此，第一步选定框架，理解web术语的基本概念已经完成，可以动手了。以上结论并不重要，重要的是去阅读rails的文档，和看具体的代码，自己理解web的运作和组织方式。

#### 选择Orm

​	rust中的orm可选的不多，diesel最有名，那就它了。diesel(吐槽一下，rust世界框架的名字，柴油机？？？)的好处在于文档很齐全，而且我们在之前定下的任务就是增删改查，目标简单。Orm选定还牵扯db的选择，emmmm,官方指引实例用的postgreSQL，那就它了！至于如何安装postgreSQL，请参考上一篇文章，已经说的很清楚，就不在这里重复了。安装上postgreSQL之后，根据diesel文档，安装diesle-cli。按照文档一步一步来就可以知道我们diesel怎么使用。现在我们开始设计我们的数据表。充分理解我们的目标之后，我们大概需要一个，用户表，文章表，分类表等几类表，具体用了什么表可以去看代码。本身也不复杂，不过如果以后继续写web项目，这个过程也是必不可少的。这里面遇到一个问题。diesel链接数据库的时候，dotenv并不能识别 .env文件中的DATABASE_URL路径，我之后把里面的路径直接写进去才成功链接数据库。但是在所有的example中.env都是同样的写法。现在尚未知道原因。

#### 开始正式使用actix_web

​	数据层的基础初步搭建好之后，开始引入actix_web。其实现在还是不能直接动手写acti_web。我们还是需要理清actix_web中的几个概念才可以开始。

> 提取器。提取器就是从handle函数中提取信息，主要提取的信息有路径，动态路径，form表单信息和其他存在body里面穿过来的信息。另外App状态也可以在handle函数中提取出来

当然以上的结论并不是一蹴而就的。需要阅读再回头阅读actix_web的文档。如果还是不理解，可以横向对比rocket的文档。个人认为rocket的文档，结构更加清晰，更能让人理解web的运行方式。其中life-cycle比较精彩，让人直观了解了rocket的运作过程，而且对handle函数的讲解更加清晰。我最后理解handler函数以及提取器就是反复阅读rocket文档的结果。现在开始启动actix服务器，加载app程序，加载router。编码的过程不再赘述，下面强调一下actix-web的架构或者说运作方式

> actix_web启动一个服务器，绑定到指定的ip和端口，在服务器上装载或者叫运行一个(多个也可以)App。其中App实例可以加载router,用router来给不同的链接(不同的链接指不同的url和请求方式)分配不同的handler处理函数。handle处理函数中使用提取器获取诸多请求信息进行处理（处理部分主要是结合ORM），根据要求返回不同的结果。web程序中的结果就是渲染不同的页面或者在页面中进行跳转。

#### 如何让diesel支持异步

​	这是个让人头痛的问题，一般来说到上一步基本的框架已经理清了，剩下的就是写代码。但是diesel不支持异步，我们如何完美结合web框架来使用它呢。在actix_web官方文档中就有这样一节。说实话，讲的不是很好。对于我来说，读了两边完全不理解是在干什么。不过好处在在提示我：快去使用Actor。那什么是Actor呢。幸运的是使用Actor模型太多了。比如erlang，AKKA和Elixir。简单来说Actor模型思路就是万物皆Actor。所有的Actor都是独立的，他们之间通过消息来交流，Actor维护一个队列(mail queue)来处理消息。好了，了解了actor的基本思路之后，继续看文档中的database一小节来明白actor到底怎么用。看懂了吗？我觉得是看不懂的，所以直接看github上的actix（不是actix_web）指引文档。所以该怎么用呢

> actor既然要通过消息来交流，那我们就需要两个东西：消息(作为信息传递)，Actor本体(作为发送和处理消息的载体)。所以，我们要做的很简单，包装一个message,然后包装一个actor.在actor里面处理消息即可。打开actor的源码你会发现一句话
>
> **Method is called for every message received by this Actor**
>
> 说明啥呢？说明我们想的没错。根据例子就知道这个actor该怎么用了。

现在知道了actor怎么用了，我们开始直面问题 "如何让diesel支持异步"。还记得前面的提取器吗，提取器可以在handler里面提取什么？应该是路径，动态路径，状态，还有body里面的信息。别的几样都是传递过来的，那数据库信息该放哪里就有点眉目了？对！存在AppState里面。App.with_state(xxx)。好了，现在看actix_web的文档database一节就知道这一套该怎么用了。几个基本的问题搞清楚之后主要的障碍就不存在了。

#### 使用Askma

​	不再强调了，看文档即可。之所以选Askma是我觉得Askma比另一个模板渲染看起来更简单。

#### 回顾

​	最后总结整合思考过程：**自顶向下，差缺补漏**

首先了解web项目的组织方式，在看不懂actix_web项目的情况下去阅读文档更为清晰的rails，建立基础概念何为web项目，他的基础架构是什么，怎么组织。解决了这三个基本问题之后就可以初步开始了。接下来处理ORM部分，这一部分就是查找资料。接下来是web项目的的具体细节问题，何为controller,何为handler何为提取器，Appstate是什么，这一部分的理解是参考rocke的文档，横向对比得来的。最后是何为actor,幸运的是资料很多，很快能达成基本的理解。

最后列出需要查阅的文档

Actix_web	 https://actix.rs/docs/

Diesel	http://diesel.rs/guides/getting-started/

Ruby on Rails	https://ruby-china.github.io/rails-guides/getting_started.htm

Rocket	https://github.com/SergioBenitez/Rocket

其他材料可以自行查阅，另外就是英文文档比汉字的容易理解一些。



