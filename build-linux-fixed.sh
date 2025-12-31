#!/bin/bash

# BBDown_GUI Linux打包脚本 - 构建AppImage (修复版)
# 使用方法: ./build-linux-fixed.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== BBDown_GUI Linux打包脚本 (修复版) ===${NC}"

# 检查是否在Linux系统上
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}错误: 此脚本只能在Linux系统上运行${NC}"
    exit 1
fi

# 检查必要的工具
echo -e "${YELLOW}检查必要的工具...${NC}"
for cmd in python3 pip pyinstaller wget unzip; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}错误: 未找到 $cmd，请先安装${NC}"
        exit 1
    fi
done

# 创建构建目录
BUILD_DIR="build_linux"
DIST_DIR="dist"
APPDIR="BBDown_GUI.AppDir"

# 保存原始工作目录
ORIGINAL_DIR=$(pwd)

echo -e "${YELLOW}清理旧构建文件...${NC}"
rm -rf "$BUILD_DIR" "$APPDIR" "$DIST_DIR/BBDown_GUI.AppImage" 2>/dev/null || true

echo -e "${YELLOW}创建构建目录...${NC}"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# 安装Python依赖
echo -e "${YELLOW}安装Python依赖...${NC}"
pip install -r requirements.txt
pip install pyinstaller

# 下载必要的依赖文件
echo -e "${YELLOW}下载必要的依赖文件...${NC}"

# 创建临时目录
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# 下载FFmpeg (Linux版本) - 添加重试机制
echo -e "${YELLOW}下载FFmpeg...${NC}"
FFMPEG_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
for i in {1..3}; do
    if wget -q --timeout=30 "$FFMPEG_URL" -O ffmpeg.tar.xz; then
        echo -e "${GREEN}FFmpeg下载成功${NC}"
        break
    else
        echo -e "${YELLOW}FFmpeg下载失败，重试 $i/3...${NC}"
        sleep 2
        if [ $i -eq 3 ]; then
            echo -e "${RED}错误: FFmpeg下载失败${NC}"
            exit 1
        fi
    fi
done

if ! tar -xf ffmpeg.tar.xz; then
    echo -e "${RED}错误: FFmpeg解压失败${NC}"
    exit 1
fi

FFMPEG_DIR=$(find . -name "ffmpeg-master-latest-linux64-gpl" -type d 2>/dev/null | head -1)
if [ -z "$FFMPEG_DIR" ]; then
    echo -e "${RED}错误: 未找到FFmpeg目录${NC}"
    exit 1
fi

if [ ! -f "$FFMPEG_DIR/bin/ffmpeg" ]; then
    echo -e "${RED}错误: 未找到ffmpeg可执行文件${NC}"
    exit 1
fi

cp "$FFMPEG_DIR/bin/ffmpeg" "$ORIGINAL_DIR/$BUILD_DIR/ffmpeg"

# 下载BBDown (Linux版本) - 添加重试机制
echo -e "${YELLow}下载BBDown...${NC}"
BBDOWN_URL=""
for i in {1..3}; do
    BBDOWN_URL=$(curl -s --max-time 10 https://api.github.com/repos/nilaoda/BBDown/releases/latest | grep -o "https://.*linux-x64.*\.zip" | head -1) || true
    if [ -n "$BBDOWN_URL" ]; then
        break
    fi
    echo -e "${YELLOW}获取BBDown URL失败，重试 $i/3...${NC}"
    sleep 2
done

if [ -z "$BBDOWN_URL" ]; then
    # 备用URL
    BBDOWN_URL="https://github.com/nilaoda/BBDown/releases/latest/download/BBDown_linux-x64.zip"
    echo -e "${YELLOW}使用备用URL: $BBDOWN_URL${NC}"
fi

for i in {1..3}; do
    if wget -q --timeout=30 "$BBDOWN_URL" -O bbdown.zip; then
        echo -e "${GREEN}BBDown下载成功${NC}"
        break
    else
        echo -e "${YELLOW}BBDown下载失败，重试 $i/3...${NC}"
        sleep 2
        if [ $i -eq 3 ]; then
            echo -e "${RED}错误: BBDown下载失败${NC}"
            exit 1
        fi
    fi
done

if ! unzip -q bbdown.zip; then
    echo -e "${RED}错误: BBDown解压失败${NC}"
    exit 1
fi

if [ ! -f "BBDown" ]; then
    # 尝试查找其他可能的文件名
    BBDOWN_FILE=$(find . -name "BBDown" -o -name "bbdown" -type f | head -1)
    if [ -z "$BBDOWN_FILE" ]; then
        echo -e "${RED}错误: 未找到BBDown可执行文件${NC}"
        exit 1
    fi
    cp "$BBDOWN_FILE" "$ORIGINAL_DIR/$BUILD_DIR/bbdown"
else
    cp BBDown "$ORIGINAL_DIR/$BUILD_DIR/bbdown"
fi

# 下载 aria2 静态二进制 (Linux) - 支持自动架构检测 + 主备下载 + 重试
echo -e "${YELLOW}下载 aria2 静态二进制...${NC}"

# 自动检测系统架构
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARIA2_FILE="aria2-x86_64-linux-musl_static.zip"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARIA2_FILE="aria2-aarch64-linux-musl_static.zip"
elif [[ "$ARCH" == "armv7l" || "$ARCH" == "armv6l" ]]; then
    ARIA2_FILE="aria2-arm-linux-musleabi_static.zip"
else
    echo -e "${RED}错误: 不支持的架构 $ARCH${NC}"
    exit 1
fi

# 主地址 + 备用加速地址
MAIN_URL="https://github.com/abcfy2/aria2-static-build/releases/download/continuous/${ARIA2_FILE}"
BACKUP_URLS=(
    "https://ghproxy.com/${MAIN_URL}"
    "https://kkgithub.com/${MAIN_URL}"
    "https://download.nuaa.cf/${MAIN_URL#https://}"
)

ARIA2_URL=""
DOWNLOAD_SUCCESS=false

# 尝试主地址（最多2次）
for i in {1..2}; do
    echo -e "${YELLOW}尝试主地址 (第 $i 次)...${NC}"
    if curl -sf --max-time 15 -I "$MAIN_URL" >/dev/null 2>&1; then
        ARIA2_URL="$MAIN_URL"
        break
    fi
    sleep 2
done

# 如果主地址失败，尝试备用地址
if [ -z "$ARIA2_URL" ]; then
    echo -e "${YELLOW}主地址不可用，尝试备用镜像...${NC}"
    for url in "${BACKUP_URLS[@]}"; do
        if curl -sf --max-time 15 -I "$url" >/dev/null 2>&1; then
            ARIA2_URL="$url"
            echo -e "${GREEN}使用备用镜像: ${url}${NC}"
            break
        fi
    done
fi

if [ -z "$ARIA2_URL" ]; then
    echo -e "${RED}错误: 所有下载地址均不可用${NC}"
    exit 1
fi

# 下载文件（带重试）
for i in {1..3}; do
    if wget -q --timeout=30 --tries=1 "$ARIA2_URL" -O "$ARIA2_FILE"; then
        echo -e "${GREEN}aria2 下载成功${NC}"
        DOWNLOAD_SUCCESS=true
        break
    else
        echo -e "${YELLOW}下载失败，重试 $i/3...${NC}"
        sleep 3
    fi
done

if [ "$DOWNLOAD_SUCCESS" = false ]; then
    echo -e "${RED}错误: aria2 下载失败${NC}"
    exit 1
fi

# 解压 ZIP（直接得到 aria2c）
if ! unzip -q "$ARIA2_FILE"; then
    echo -e "${RED}错误: 解压失败${NC}"
    exit 1
fi

# 检查 aria2c 是否存在（就在当前目录）
if [ ! -f "aria2c" ]; then
    echo -e "${RED}错误: 解压后未找到 aria2c 可执行文件${NC}"
    exit 1
fi

# 复制到目标目录并赋予执行权限
cp "aria2c" "$ORIGINAL_DIR/$BUILD_DIR/aria2c"
chmod +x "$ORIGINAL_DIR/$BUILD_DIR/aria2c"

# 可选：清理临时文件
rm -f "$ARIA2_FILE" aria2c

cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

# 使用PyInstaller构建可执行文件
echo -e "${YELLOW}使用PyInstaller构建可执行文件...${NC}"
pyinstaller --noconfirm --onefile --noconsole \
    --icon "./BBDown_GUI/UI/favicon.png" \
    --add-data "./BBDown_GUI/UI/favicon.png:./UI" \
    --distpath "$BUILD_DIR" \
    "./build-to-exe.py"

if [ ! -f "$BUILD_DIR/build-to-exe" ]; then
    echo -e "${RED}错误: PyInstaller构建失败${NC}"
    exit 1
fi

mv "$BUILD_DIR/build-to-exe" "$BUILD_DIR/BBDown_GUI"

# 创建AppDir结构
echo -e "${YELLOW}创建AppDir结构...${NC}"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/metainfo"

# 复制文件到AppDir
cp "$BUILD_DIR/BBDown_GUI" "$APPDIR/usr/bin/"
cp "$BUILD_DIR/ffmpeg" "$APPDIR/usr/bin/"
cp "$BUILD_DIR/bbdown" "$APPDIR/usr/bin/"
cp "$BUILD_DIR/aria2c" "$APPDIR/usr/bin/"
cp "./BBDown_GUI/UI/favicon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/bbdown-gui.png"

# 创建.desktop文件
cat > "$APPDIR/usr/share/applications/bbdown-gui.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=BBDown GUI
GenericName=Bilibili Video Downloader GUI
Comment=GUI for BBDown video downloader
Exec=bbdown-gui
Icon=bbdown-gui
Categories=AudioVideo;Video;
Terminal=false
StartupNotify=true
StartupWMClass=BBDown_GUI
EOF

# 创建AppRun文件
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash

# 设置环境变量
export PATH="$APPDIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$APPDIR/usr/lib:$LD_LIBRARY_PATH"

# 运行应用程序
exec "$APPDIR/usr/bin/BBDown_GUI" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# 创建.appdata.xml文件
cat > "$APPDIR/usr/share/metainfo/bbdown-gui.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.github.muwenyan521.bbdown-gui</id>
  <name>BBDown GUI</name>
  <summary>GUI for BBDown video downloader</summary>
  <description>
    <p>A graphical user interface for BBDown, a command-line video downloader for Bilibili.</p>
  </description>
  <metadata_license>MIT</metadata_license>
  <project_license>MIT</project_license>
  <url type="homepage">https://github.com/muwenyan521/BBDown_GUI</url>
  <developer>
    <name>BBDown GUI Developers</name>
  </developer>
  <update_contact>muwenyan521@gmail.com</update_contact>
  <launchable type="desktop-id">com.github.muwenyan521.bbdown-gui.desktop</launchable>
  <content_rating type="oars-1.1">
    <content_attribute id="violence-cartoon">none</content_attribute>
    <content_attribute id="violence-fantasy">none</content_attribute>
    <content_attribute id="violence-realistic">none</content_attribute>
    <content_attribute id="violence-bloodshed">none</content_attribute>
    <content_attribute id="violence-sexual">none</content_attribute>
    <content_attribute id="violence-desecration">none</content_attribute>
    <content_attribute id="violence-slavery">none</content_attribute>
    <content_attribute id="violence-worship">none</content_attribute>
    <content_attribute id="drugs-alcohol">none</content_attribute>
    <content_attribute id="drugs-narcotics">none</content_attribute>
    <content_attribute id="drugs-tobacco">none</content_attribute>
    <content_attribute id="sex-nudity">none</content_attribute>
    <content_attribute id="sex-themes">none</content_attribute>
    <content_attribute id="sex-homosexuality">none</content_attribute>
    <content_attribute id="sex-prostitution">none</content_attribute>
    <content_attribute id="sex-adultery">none</content_attribute>
    <content_attribute id="sex-appearance">none</content_attribute>
    <content_attribute id="language-profanity">none</content_attribute>
    <content_attribute id="language-humor">none</content_attribute>
    <content_attribute id="language-discrimination">none</content_attribute>
    <content_attribute id="social-chat">none</content_attribute>
    <content_attribute id="social-info">none</content_attribute>
    <content_attribute id="social-audio">none</content_attribute>
    <content_attribute id="social-location">none</content_attribute>
    <content_attribute id="social-contacts">none</content_attribute>
    <content_attribute id="money-purchasing">none</content_attribute>
    <content_attribute id="money-gambling">none</content_attribute>
  </content_rating>
  <releases>
    <release version="1.0.0" date="2024-01-01"/>
  </releases>
</component>
EOF

# 下载linuxdeploy来构建AppImage - 添加重试机制
echo -e "${YELLOW}下载linuxdeploy...${NC}"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
for i in {1..3}; do
    if wget -q --timeout=30 "$LINUXDEPLOY_URL" -O linuxdeploy.AppImage; then
        echo -e "${GREEN}linuxdeploy下载成功${NC}"
        break
    else
        echo -e "${YELLOW}linuxdeploy下载失败，重试 $i/3...${NC}"
        sleep 2
        if [ $i -eq 3 ]; then
            echo -e "${RED}错误: linuxdeploy下载失败${NC}"
            exit 1
        fi
    fi
done

chmod +x linuxdeploy.AppImage

# 构建AppImage
echo -e "${YELLOW}构建AppImage...${NC}"
./linuxdeploy.AppImage \
    --appdir "$APPDIR" \
    --output appimage \
    --icon-file "./BBDown_GUI/UI/favicon.png" \
    --desktop-file "$APPDIR/usr/share/applications/bbdown-gui.desktop"

# 移动生成的AppImage到dist目录
if ls BBDown_GUI*.AppImage 1> /dev/null 2>&1; then
    mv BBDown_GUI*.AppImage "$DIST_DIR/BBDown_GUI.AppImage"
else
    echo -e "${RED}错误: 未生成AppImage文件${NC}"
    exit 1
fi

# 清理
echo -e "${YELLOW}清理临时文件...${NC}"
rm -rf "$BUILD_DIR" "$APPDIR" linuxdeploy.AppImage 2>/dev/null || true

echo -e "${GREEN}=== 构建完成 ===${NC}"
echo -e "${GREEN}AppImage已生成: $DIST_DIR/BBDown_GUI.AppImage${NC}"
echo -e "${YELLOW}要运行AppImage，请执行: chmod +x $DIST_DIR/BBDown_GUI.AppImage && ./$DIST_DIR/BBDown_GUI.AppImage${NC}"
