#!/bin/bash
# 在 Obsidian 中创建新博客文章

OBSIDIAN_BLOG_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Blog"

# 检查目录
if [ ! -d "$OBSIDIAN_BLOG_DIR" ]; then
    mkdir -p "$OBSIDIAN_BLOG_DIR"
    echo "✅ 已创建 Obsidian Blog 目录"
fi

# 获取文章标题（支持命令行参数或交互式输入）
if [ -n "$1" ]; then
    title="$1"
else
    read -p "请输入文章标题: " title
fi

if [ -z "$title" ]; then
    echo "❌ 标题不能为空"
    exit 1
fi

# 生成文件名（替换空格为连字符）
filename=$(echo "$title" | sed 's/ /-/g').md
filepath="$OBSIDIAN_BLOG_DIR/$filename"

# 生成日期
date=$(date +"%Y-%m-%d %H:%M:%S")

# 创建文章模板
cat > "$filepath" << EOF
---
title: $title
date: $date
categories:
tags:
---

<!-- 在这里开始写文章 -->

EOF

echo "✅ 文章已创建: $filepath"
echo "📝 请在 Obsidian 中打开并编辑"

# 尝试用 Obsidian 打开
open "obsidian://open?vault=Obsidian&file=Blog/$filename"
