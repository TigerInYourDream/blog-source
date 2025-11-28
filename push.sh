#!/bin/bash
echo "🚀 推送博客源码到 GitHub"

# 确保我们在最新的状态
git pull origin source

# 添加所有更改
git add .

# 生成随机emoji组合
EMOJIS=("🚀" "✨" "🎨" "🔥" "⚡" "🌟" "💫" "🎯" "🎪" "🎭" "🎬" "🎸" "🎮" "🎲" "🎯" "🏆" "💎" "🔮" "🌈" "🌊")
ACTIONS=("Update" "Sync" "Deploy" "Push" "Commit" "Ship" "Launch" "Release" "Upload" "Boost")
VIBES=("Awesome" "Epic" "Legendary" "Blazing" "Stellar" "Cosmic" "Supreme" "Ultimate" "Magnificent" "Incredible")

# 随机选择
EMOJI1=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
EMOJI2=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
ACTION=${ACTIONS[$RANDOM % ${#ACTIONS[@]}]}
VIBE=${VIBES[$RANDOM % ${#VIBES[@]}]}

# 获取当前时间
TIMESTAMP=$(date "+%Y.%m.%d %H:%M")

# 构建commit信息
COMMIT_MSG="$EMOJI1 $ACTION: $VIBE Blog Update $EMOJI2

📅 Time: $TIMESTAMP
🔧 Auto-generated commit
📝 Blog source synchronized
⚡ Performance optimized
🎯 Ready for deployment"

# 提交更改
git commit -s -m "$COMMIT_MSG"

# 推送到 source 分支
git push origin source

echo "✅ 博客源码推送完成！"
echo "📊 Commit: $EMOJI1 $ACTION: $VIBE Blog Update $EMOJI2"