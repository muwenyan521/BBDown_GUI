#!/bin/bash

# BBDown_GUI Linux打包脚本 - 构建AppImage
# 使用方法: ./build-linux.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== BBDown_GUI Linux打包脚本 ===${NC}"

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
rm -rf "$BUILD_DIR" "$APPDIR" "$DIST_DIR/BBDown_GUI.AppImage"

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

# 下载FFmpeg (Linux版本)
echo -e "${YELLOW}下载FFmpeg...${NC}"
FFMPEG_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
wget -q "$FFMPEG_URL" -O ffmpeg.tar.xz
tar -xf ffmpeg.tar.xz
FFMPEG_DIR=$(find . -name "ffmpeg-master-latest-linux64-gpl" -type d)
cp "$FFMPEG_DIR/bin/ffmpeg" "$ORIGINAL_DIR/$BUILD_DIR/ffmpeg"

# 下载BBDown (Linux版本)
echo -e "${YELLOW}下载BBDown...${NC}"
BBDOWN_URL=$(curl -s https://api.github.com/repos/nilaoda/BBDown/releases/latest | grep -o "https://.*linux-x64.*\.zip" | head -1)
if [ -z "$BBDOWN_URL" ]; then
    # 备用URL
    BBDOWN_URL="https://github.com/nilaoda/BBDown/releases/latest/download/BBDown_linux-x64.zip"
fi
wget -q "$BBDOWN_URL" -O bbdown.zip
unzip -q bbdown.zip
cp BBDown "$ORIGINAL_DIR/$BUILD_DIR/bbdown"

# 下载aria2 (Linux版本)
echo -e "${YELLOW}下载aria2...${NC}"
ARIA2_URL=$(curl -s https://api.github.com/repos/aria2/aria2/releases/latest | grep -o "https://.*linux.*\.tar\.xz" | head -1)
if [ -z "$ARIA2_URL" ]; then
    # 备用URL
    ARIA2_URL="https://github.com/aria2/aria2/releases/latest/download/aria2-1.37.0-linux-gnu-64bit-build1.tar.xz"
fi
wget -q "$ARIA2_URL" -O aria2.tar.xz
tar -xf aria2.tar.xz
ARIA2_DIR=$(find . -name "aria2-*" -type d | head -1)
cp "$ARIA2_DIR/bin/aria2c" "$ORIGINAL_DIR/$BUILD_DIR/aria2c"

cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

# 使用PyInstaller构建可执行文件
echo -e "${YELLOW}使用PyInstaller构建可执行文件...${NC}"
pyinstaller --noconfirm --onefile --noconsole \
    --icon "./BBDown_GUI/UI/favicon.ico" \
    --add-data "./BBDown_GUI/UI/favicon.ico:./UI" \
    --distpath "$BUILD_DIR" \
    "./build-to-exe.py"

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
cp "./BBDown_GUI/UI/favicon.ico" "$APPDIR/usr/share/icons/hicolor/256x256/apps/bbdown-gui.ico"

# 创建.desktop文件
cat > "$APPDIR/usr/share/applications/bbdown-gui.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=BBDown GUI
Comment=GUI for BBDown video downloader
Exec=bbdown-gui
Icon=bbdown-gui
Categories=AudioVideo;Video;
Terminal=false
StartupNotify=true
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
  <id>bbdown-gui.desktop</id>
  <name>BBDown GUI</name>
  <summary>GUI for BBDown video downloader</summary>
  <description>
    <p>A graphical user interface for BBDown, a command-line video downloader for Bilibili.</p>
  </description>
  <metadata_license>MIT</metadata_license>
  <project_license>MIT</project_license>
  <url type="homepage">https://github.com/muwenyan521/BBDown_GUI</url>
  <developer_name>BBDown GUI Developers</developer_name>
  <update_contact>muwenyan521</update_contact>
  <releases>
    <release version="1.0.0" date="2024-01-01"/>
  </releases>
</component>
EOF

# 下载linuxdeploy来构建AppImage
echo -e "${YELLOW}下载linuxdeploy...${NC}"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
wget -q "$LINUXDEPLOY_URL" -O linuxdeploy.AppImage
chmod +x linuxdeploy.AppImage

# 构建AppImage
echo -e "${YELLOW}构建AppImage...${NC}"
./linuxdeploy.AppImage \
    --appdir "$APPDIR" \
    --output appimage \
    --icon-file "./BBDown_GUI/UI/favicon.ico" \
    --desktop-file "$APPDIR/usr/share/applications/bbdown-gui.desktop"

# 移动生成的AppImage到dist目录
mv BBDown_GUI*.AppImage "$DIST_DIR/BBDown_GUI.AppImage"

# 清理
echo -e "${YELLOW}清理临时文件...${NC}"
rm -rf "$BUILD_DIR" "$APPDIR" linuxdeploy.AppImage

echo -e "${GREEN}=== 构建完成 ===${NC}"
echo -e "${GREEN}AppImage已生成: $DIST_DIR/BBDown_GUI.AppImage${NC}"
echo -e "${YELLOW}要运行AppImage，请执行: chmod +x $DIST_DIR/BBDown_GUI.AppImage && ./$DIST_DIR/BBDown_GUI.AppImage${NC}"
