#!/bin/bash
echo "推送博客源码到 GitHub"

# 确保我们在最新的状态
git pull origin source

# 添加所有更改
git add .

# 提交更改
git commit -s -m "upd |> commit source to github"

# 推送到 source 分支
git push origin source

echo "博客源码推送完成"