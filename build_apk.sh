#!/bin/bash

# StoryCoe Flutter APK 打包脚本
# 自动添加时间戳到APK文件名，并上传到Google云盘

# 进入项目目录
cd "$(dirname "$0")"

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Google云盘配置
RCLONE_REMOTE="googledrive"
GDRIVE_FOLDER="StoryCoe/APK"

echo "=========================================="
echo "StoryCoe Flutter APK 打包"
echo "时间: $(date)"
echo "=========================================="

# 打包 APK (生产环境)
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=http://47.85.201.118:8000

# 检查打包是否成功
if [ $? -eq 0 ]; then
  # 原始APK路径
  ORIGINAL_APK="build/app/outputs/flutter-apk/app-release.apk"

  # 新的APK文件名（带时间戳）
  NEW_APK="build/app/outputs/flutter-apk/storycoe_${TIMESTAMP}.apk"

  # 重命名APK
  mv "$ORIGINAL_APK" "$NEW_APK"

  # 获取文件大小
  SIZE=$(ls -lh "$NEW_APK" | awk '{print $5}')

  echo ""
  echo "=========================================="
  echo "✓ 打包成功！"
  echo "=========================================="
  echo "文件名: storycoe_${TIMESTAMP}.apk"
  echo "文件大小: $SIZE"
  echo "完整路径: $(pwd)/$NEW_APK"
  echo "=========================================="

  # 上传到Google云盘
  echo ""
  echo "正在上传到 Google 云盘..."
  rclone copy "$NEW_APK" "${RCLONE_REMOTE}:${GDRIVE_FOLDER}" --progress

  if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ 上传成功！"
    echo "=========================================="
    echo "云盘路径: ${GDRIVE_FOLDER}/storycoe_${TIMESTAMP}.apk"
    echo "=========================================="
  else
    echo ""
    echo "=========================================="
    echo "✗ 上传失败，请检查 rclone 配置"
    echo "=========================================="
  fi
else
  echo ""
  echo "=========================================="
  echo "✗ 打包失败，请检查错误信息"
  echo "=========================================="
  exit 1
fi