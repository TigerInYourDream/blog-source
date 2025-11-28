#!/bin/bash
# Obsidian 到 Hexo 博客同步脚本

# 配置路径
OBSIDIAN_BLOG_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Blog"
HEXO_POST_DIR="$HOME/Documents/blog-source/source/_posts"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}开始同步 Obsidian 文章到 Hexo...${NC}"

# 检查 Obsidian 目录是否存在
if [ ! -d "$OBSIDIAN_BLOG_DIR" ]; then
    echo "❌ Obsidian Blog 目录不存在: $OBSIDIAN_BLOG_DIR"
    echo "请先在 Obsidian 中创建 Blog 文件夹"
    exit 1
fi

# 同步 markdown 文件
rsync -av --include='*/' \
    --include='*.md' \
    --include='*.png' \
    --include='*.jpg' \
    --include='*.jpeg' \
    --include='*.gif' \
    --include='*.svg' \
    --exclude='*' \
    "$OBSIDIAN_BLOG_DIR/" "$HEXO_POST_DIR/"

# 移除 iCloud 下载占位符（如果有）
find "$HEXO_POST_DIR" -name "*.icloud" -delete

echo -e "${GREEN}✅ 同步完成！${NC}"
echo "文章数量: $(find "$HEXO_POST_DIR" -name "*.md" | wc -l)"

# 询问是否推送到 GitHub（触发自动部署）
read -p "是否推送到 GitHub 触发自动部署？(y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$HOME/Documents/blog-source"
    git add .
    git commit -m "同步 Obsidian 文章更新"
    git push
    echo -e "${GREEN}✅ 已推送到 GitHub，等待自动部署...${NC}"
fi
