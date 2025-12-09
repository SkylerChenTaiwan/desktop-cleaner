#!/bin/bash
set -e

# 設定
APP_NAME="DesktopCleaner"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR=".build/release"
OUTPUT_DIR="dist"

echo "=== Desktop Cleaner 打包腳本 ==="

# 1. 編譯 Release 版本
echo "[1/4] 編譯中..."
swift build -c release

# 2. 建立 Bundle 結構
echo "[2/4] 建立 App Bundle..."
rm -rf "${OUTPUT_DIR}/${BUNDLE_NAME}"
mkdir -p "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/Resources"

# 3. 複製檔案
echo "[3/4] 複製檔案..."
cp "${BUILD_DIR}/${APP_NAME}" "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/MacOS/"
cp "Resources/Info.plist" "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/"

# 4. 簽名
echo "[4/4] 簽名中..."
codesign --sign - --force --deep "${OUTPUT_DIR}/${BUNDLE_NAME}"

echo ""
echo "=== 打包完成 ==="
echo "App Bundle: ${OUTPUT_DIR}/${BUNDLE_NAME}"
echo ""
echo "下一步：執行 ./scripts/install.sh 安裝"
