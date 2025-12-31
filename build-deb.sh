#!/bin/bash

# BBDown_GUI Debian打包脚本 - 构建.deb包
# 使用方法: ./build-deb.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== BBDown_GUI Debian打包脚本 ===${NC}"

# 检查是否在Linux系统上
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}错误: 此脚本只能在Linux系统上运行${NC}"
    exit 1
fi

# 检查必要的工具
echo -e "${YELLOW}检查必要的工具...${NC}"
for cmd in python3 pip pyinstaller wget unzip dpkg-deb fakeroot; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}错误: 未找到 $cmd，请先安装${NC}"
        exit 1
    fi
done

# 设置变量
VERSION="1.0.0"
ARCH="amd64"
PACKAGE_NAME="bbdown-gui"
BUILD_DIR="build_deb"
DIST_DIR="dist"
DEB_DIR="$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}"

# 保存原始工作目录
ORIGINAL_DIR=$(pwd)

echo -e "${YELLOW}清理旧构建文件...${NC}"
rm -rf "$BUILD_DIR" "$DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo -e "${YELLOW}创建构建目录结构...${NC}"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# 创建DEB包目录结构
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$DEB_DIR/usr/share/doc/$PACKAGE_NAME"
mkdir -p "$DEB_DIR/usr/share/$PACKAGE_NAME"

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

# 复制文件到DEB目录
echo -e "${YELLOW}复制文件到DEB目录...${NC}"
cp "$BUILD_DIR/BBDown_GUI" "$DEB_DIR/usr/bin/bbdown-gui"
cp "$BUILD_DIR/ffmpeg" "$DEB_DIR/usr/share/$PACKAGE_NAME/"
cp "$BUILD_DIR/bbdown" "$DEB_DIR/usr/share/$PACKAGE_NAME/"
cp "$BUILD_DIR/aria2c" "$DEB_DIR/usr/share/$PACKAGE_NAME/"
cp "./BBDown_GUI/UI/favicon.ico" "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/bbdown-gui.ico"

# 创建包装脚本
cat > "$DEB_DIR/usr/bin/bbdown-gui-wrapper" << 'EOF'
#!/bin/bash

# 包装脚本，设置正确的路径
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
APP_DIR="/usr/share/bbdown-gui"

# 设置环境变量
export PATH="$APP_DIR:$PATH"

# 运行应用程序
exec "$SCRIPT_DIR/bbdown-gui" "$@"
EOF
chmod +x "$DEB_DIR/usr/bin/bbdown-gui-wrapper"

# 创建.desktop文件
cat > "$DEB_DIR/usr/share/applications/bbdown-gui.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=BBDown GUI
Comment=GUI for BBDown video downloader
Exec=bbdown-gui-wrapper
Icon=bbdown-gui
Categories=AudioVideo;Video;
Terminal=false
StartupNotify=true
EOF

# 创建版权文件
cat > "$DEB_DIR/usr/share/doc/$PACKAGE_NAME/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: BBDown GUI
Source: https://github.com/muwenyan521/BBDown_GUI

Files: *
Copyright: 2024 BBDown GUI Developers
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# 创建changelog文件
cat > "$DEB_DIR/usr/share/doc/$PACKAGE_NAME/changelog.Debian.gz" << 'EOF' | gzip -c > "$DEB_DIR/usr/share/doc/$PACKAGE_NAME/changelog.Debian.gz"
bbdown-gui (1.0.0) unstable; urgency=medium

  * Initial release of BBDown GUI
  * Added Linux support with AppImage and .deb packages
  * Improved cross-platform compatibility

 -- BBDown GUI Developers <muwenyan521>  Wed, 01 Jan 2024 00:00:00 +0800
EOF

# 创建控制文件
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: BBDown GUI Developers <muwenyan521>
Installed-Size: $(du -sk "$DEB_DIR" | cut -f1)
Depends: python3, python3-pyqt5, libqt5core5a, libqt5gui5, libqt5widgets5, libqt5network5, libc6 (>= 2.34)
Recommends: ffmpeg, aria2
Section: video
Priority: optional
Homepage: https://github.com/muwenyan521/BBDown_GUI
Description: GUI for BBDown video downloader
 BBDown GUI is a graphical user interface for BBDown, a command-line
 video downloader for Bilibili. It provides an easy-to-use interface
 for downloading videos from Bilibili with various options and settings.
 .
 Features:
  * User-friendly graphical interface
  * Support for multiple video quality options
  * Built-in FFmpeg for video processing
  * Built-in aria2 for accelerated downloading
  * Cross-platform support (Windows, Linux, macOS)
EOF

# 创建后安装脚本
cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash

# 更新桌面数据库
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q /usr/share/applications
fi

# 更新图标缓存
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor
fi

# 设置文件权限
chmod 755 /usr/share/bbdown-gui/ffmpeg
chmod 755 /usr/share/bbdown-gui/bbdown
chmod 755 /usr/share/bbdown-gui/aria2c

echo "BBDown GUI has been successfully installed!"
echo "You can launch it from your application menu or by running 'bbdown-gui' in terminal."
EOF
chmod 755 "$DEB_DIR/DEBIAN/postinst"

# 创建卸载前脚本
cat > "$DEB_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash

# 清理临时文件
rm -rf /tmp/bbdown-gui-*
EOF
chmod 755 "$DEB_DIR/DEBIAN/prerm"

# 构建DEB包
echo -e "${YELLOW}构建DEB包...${NC}"
fakeroot dpkg-deb --build "$DEB_DIR" "$DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

# 清理
echo -e "${YELLOW}清理临时文件...${NC}"
rm -rf "$BUILD_DIR"

echo -e "${GREEN}=== 构建完成 ===${NC}"
echo -e "${GREEN}DEB包已生成: $DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb${NC}"
echo -e "${YELLOW}要安装DEB包，请执行: sudo dpkg -i $DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb${NC}"
echo -e "${YELLOW}如果遇到依赖问题，请执行: sudo apt-get install -f${NC}"
