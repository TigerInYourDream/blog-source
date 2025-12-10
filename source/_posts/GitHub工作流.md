---
title: GitHub工作流
abbrlink: 53869
date: 2025-11-28 19:46:34
tags:
---

# Github工作流

虽然在ai时代写这些小文章的意义在降低，但是自己的体会还是有必要写出来.

现在有一个实际的场景：为github上存在的项目做pr. （当然已经有无数的文章告诉我们如何去给开源项目pr.）一般的流程是fork项目，接下来clone自己仓库下的项目到本地。然后新的分支，写代码，push到自己的fork过来的仓库上去。接下来去github上创建新的pr，写一份详细的pr说明，包含如何设计，代码目的以及自己变更的代码等等。如果在进一步，自己已经给开源项目做了很多贡献，拥有了对开源项目的review和权限，如何管理自己的代码和官方库呢。比如一个简单的场景，其他作者Bob给官方库提了一个全新的pr, 暂且定位pr404。如何在本地review这个pr呢。

我现在提出我的实际工作流。 代码可以有不止一个远程的上游。比如我们按照惯例，把自己拥有修改权限的远程仓库叫做 origin, 然后添加官方的仓库版本作为Upstream. 这个upstream只有阅读，拉取权限

```shell
git remote add upstream https://github.com/superman/super_power.git
```

如果需要在本地review代码最好的办法是安装gh 

```
brew install gh
```

然后需要

```
 gh repo set-default superman/super_power
```

可以参考

https://cli.github.com/manual/gh_repo_set-default

接下来拉取需要的pr

`gh pr checkout 404`

现在本地就有一个 pr-404新分支供我自己查看了。

注意因为设置了gh 的default 为官方仓库，gh所有的操作都是针对官方的来。用完之后再切回来

`gh repo set-default youname/super_power`

当然gh不影响本地操作，你需要修改代码只需要

```
git branch -D pr-404 // 删除这个分支
git switch youbranch
```

当然可以用

gh repo set-default --view 来查看默认的分支，多用就像多用git status一样
