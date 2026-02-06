#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BBDown_GUI Linux Build Script
=============================
支持 Debug 和 Release 两种构建模式
使用 PyInstaller 打包应用程序为单个可执行文件
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# ==================== 配置 ====================
PROJECT_NAME = "BBDown_GUI"
VERSION = "1.0.0"

# 源文件路径
SOURCE_DIR = Path(__file__).parent / PROJECT_NAME
MAIN_ENTRY = SOURCE_DIR / "__main__.py"
UI_DIR = SOURCE_DIR / "UI"
FORM_DIR = SOURCE_DIR / "Form"

# 构建路径
BUILD_DIR = Path(__file__).parent / "build"
DIST_DIR = Path(__file__).parent / "dist"
SPEC_FILE = Path(__file__).parent / f"{PROJECT_NAME}.spec"

# 图标路径
ICON_PATH = UI_DIR / "favicon.ico"

# 打包模式：True = Debug, False = Release
DEBUG_MODE = False

# ==================== 日志函数 ====================
def log(message: str, level: str = "INFO"):
    """带时间戳的日志输出"""
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    level_prefix = {
        "INFO": "[INFO]",
        "DEBUG": "[DEBUG]",
        "WARNING": "[WARNING]",
        "ERROR": "[ERROR]",
        "SUCCESS": "[SUCCESS]"
    }.get(level, "[INFO]")
    print(f"{timestamp} {level_prefix} {message}")

def log_section(title: str):
    """打印分隔标题"""
    log("=" * 60)
    log(title)
    log("=" * 60)

# ==================== 清理函数 ====================
def clean_build():
    """清理构建产物"""
    log_section("清理构建产物")
    
    paths_to_remove = [BUILD_DIR, DIST_DIR, SPEC_FILE]
    
    # 清理临时文件
    patterns = ["__pycache__", "*.pyc", "*.pyo", ".pytest_cache", ".coverage", "htmlcov"]
    
    for pattern in patterns:
        for path in Path(__file__).parent.rglob(pattern):
            try:
                if path.is_file():
                    path.unlink()
                    log(f"删除文件: {path}")
                elif path.is_dir():
                    shutil.rmtree(path)
                    log(f"删除目录: {path}")
            except Exception as e:
                log(f"删除失败 {path}: {e}", "WARNING")
    
    for path in paths_to_remove:
        try:
            if path.exists():
                if path.is_file():
                    path.unlink()
                    log(f"删除文件: {path}")
                elif path.is_dir():
                    shutil.rmtree(path)
                    log(f"删除目录: {path}")
        except Exception as e:
            log(f"删除失败 {path}: {e}", "WARNING")
    
    log("清理完成", "SUCCESS")

# ==================== 依赖安装 ====================
def check_pyinstaller_installed():
    """检查 PyInstaller 是否已安装"""
    try:
        result = subprocess.run(
            [sys.executable, "-m", "PyInstaller", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            version = result.stdout.strip()
            log(f"PyInstaller 已安装，版本: {version}")
            return True
    except FileNotFoundError:
        pass
    except Exception as e:
        log(f"检查 PyInstaller 时发生异常: {e}", "WARNING")
    
    log("PyInstaller 未安装", "WARNING")
    return False

def install_pyinstaller():
    """安装 PyInstaller 和相关构建依赖"""
    log_section("安装 PyInstaller")
    
    packages = [
        "pyinstaller",  # 不限制版本，让pip选择兼容版本
        "altgraph>=0.17",
        "pefile>=2022.5.30",
        "pyinstaller-hooks-contrib>=2022.0",
    ]
    
    # 首先尝试正常安装
    try:
        log("正在安装 PyInstaller 和构建依赖...")
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install"] + packages,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            log("PyInstaller 安装成功", "SUCCESS")
            return True
        
        # 检查是否是外部管理环境错误 (PEP 668)
        stderr = result.stderr.lower()
        if "externally-managed-environment" in stderr or "break-system-packages" in stderr:
            log("检测到 Python 外部管理环境限制 (PEP 668)", "WARNING")
            log("正在尝试使用 --break-system-packages 标志重新安装...")
            
            result = subprocess.run(
                [sys.executable, "-m", "pip", "install", "--break-system-packages"] + packages,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                log("PyInstaller 安装成功 (使用 --break-system-packages)", "SUCCESS")
                return True
            else:
                log(f"PyInstaller 安装失败: {result.stderr}", "ERROR")
                log("提示: 如果仍无法安装，请尝试使用 sudo 权限运行脚本", "ERROR")
                return False
        else:
            log(f"PyInstaller 安装失败: {result.stderr}", "ERROR")
            log("提示: 如果遇到权限错误，请尝试使用 sudo 权限运行脚本", "ERROR")
            return False
            
    except Exception as e:
        error_msg = str(e)
        log(f"PyInstaller 安装异常: {error_msg}", "ERROR")
        
        # 检测 Python 3.15 与 pip 的兼容性问题
        if "WheelDistribution" in error_msg or "locate_file" in error_msg:
            log("")
            log("检测到 Python 3.15 与系统 pip 存在兼容性问题！", "ERROR")
            log("这可能是由于使用了 Python 3.15 预发布版本导致的。")
            log("")
            log("故障排除指南:", "INFO")
            log("-" * 50)
            log("")
            log("方案 1: 使用 Python 3.12 稳定版（推荐）", "INFO")
            log("  许多 Linux 发行版已默认安装 Python 3.12:")
            log("  sudo apt install python3.12 python3.12-venv python3.12-dev  # Debian/Ubuntu")
            log("  sudo dnf install python3.12  # Fedora")
            log("  sudo pacman -S python312  # Arch Linux")
            log("")
            log("方案 2: 使用虚拟环境（推荐）", "INFO")
            log("  创建虚拟环境:")
            log("  python3.12 -m venv venv")
            log("  source venv/bin/activate")
            log("  python build-linux.py")
            log("")
            log("方案 3: 手动安装 PyInstaller 到用户目录", "INFO")
            log("  pip install --user pyinstaller altgraph pefile pyinstaller-hooks-contrib")
            log("")
            log("-" * 50)
            log("建议优先使用 Python 3.12 稳定版或虚拟环境来避免此类问题。")
            log("")
        
        return False

def install_dependencies():
    """安装项目依赖"""
    log_section("安装依赖")
    
    requirements_file = Path(__file__).parent / "requirements.txt"
    
    if not requirements_file.exists():
        log("未找到 requirements.txt，跳过依赖安装", "WARNING")
        return
    
    log(f"安装依赖: {requirements_file}")
    
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            log("依赖安装成功", "SUCCESS")
        else:
            log(f"依赖安装失败: {result.stderr}", "ERROR")
            sys.exit(1)
            
    except Exception as e:
        log(f"依赖安装异常: {e}", "ERROR")
        sys.exit(1)

# ==================== PyInstaller 命令构建 ====================
def build_executable():
    """使用 PyInstaller 构建可执行文件"""
    log_section("开始构建可执行文件")
    
    # 确保输出目录存在
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    
    # 构建 PyInstaller 命令
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--noconfirm",           # 覆盖已存在的文件不询问
        "--onefile",             # 打包成单个可执行文件
        "--windowed",            # 不显示控制台窗口（GUI应用）
        "--name", PROJECT_NAME,  # 输出文件名
        "--icon", str(ICON_PATH),  # 应用图标
        "--distpath", str(DIST_DIR),  # 输出目录
        "--workpath", str(BUILD_DIR),  # 构建工作目录
        "--clean",               # 清理临时文件
    ]
    
    # Debug 模式添加调试信息
    if DEBUG_MODE:
        cmd.append("--debug=all")
        cmd.append("--console")  # Debug 模式显示控制台
    else:
        cmd.append("--noconsole")  # Release 模式不显示控制台
    
    # 添加数据文件 - UI目录 (Linux 使用 : 分隔)
    cmd.extend(["--add-data", f"{UI_DIR}:UI"])
    
    # 添加数据文件 - Form目录
    cmd.extend(["--add-data", f"{FORM_DIR}:Form"])
    
    # 添加隐藏导入（PyQt5 相关）
    hidden_imports = [
        "PyQt5.QtCore",
        "PyQt5.QtGui",
        "PyQt5.QtWidgets",
        "PyQt5.QtNetwork",
        "PyQt5.QtXml",
        "json",
        "os",
        "sys",
        "subprocess",
    ]
    
    for hidden_import in hidden_imports:
        cmd.extend(["--hidden-import", hidden_import])
    
    # 添加收集的所有文件
    cmd.extend(["--collect-all", "BBDown_GUI"])
    
    # 添加入口文件
    cmd.append(str(MAIN_ENTRY))
    
    # 打印构建命令
    log(f"PyInstaller 命令: {' '.join(cmd)}")
    log(f"入口文件: {MAIN_ENTRY}")
    log(f"图标文件: {ICON_PATH}")
    log(f"UI目录: {UI_DIR}")
    log(f"Form目录: {FORM_DIR}")
    
    # 执行构建
    log("执行 PyInstaller 构建...")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(Path(__file__).parent)
        )
        
        # 输出构建日志
        if result.stdout:
            log("构建输出:")
            for line in result.stdout.splitlines():
                log(f"  {line}")
        
        if result.stderr:
            log("构建错误/警告:")
            for line in result.stderr.splitlines():
                log(f"  {line}", "WARNING")
        
        if result.returncode == 0:
            # 检查输出文件
            output_file = DIST_DIR / PROJECT_NAME
            if output_file.exists():
                file_size = output_file.stat().st_size / (1024 * 1024)  # MB
                log(f"构建成功！输出文件: {output_file}", "SUCCESS")
                log(f"文件大小: {file_size:.2f} MB", "SUCCESS")
                
                # 设置可执行权限
                os.chmod(str(output_file), 0o755)
                log("已设置文件可执行权限", "SUCCESS")
                
                return True
            else:
                log(f"输出文件不存在: {output_file}", "ERROR")
                return False
        else:
            log(f"构建失败！返回码: {result.returncode}", "ERROR")
            return False
            
    except Exception as e:
        log(f"构建异常: {e}", "ERROR")
        return False

# ==================== 后处理 ====================
def post_build():
    """构建后处理"""
    log_section("后处理")
    
    output_file = DIST_DIR / PROJECT_NAME
    
    if not output_file.exists():
        log("构建产物不存在，跳过后处理", "WARNING")
        return
    
    # 清理临时目录
    temp_dirs = [BUILD_DIR]
    for temp_dir in temp_dirs:
        if temp_dir.exists():
            try:
                shutil.rmtree(temp_dir)
                log(f"清理临时目录: {temp_dir}")
            except Exception as e:
                log(f"清理临时目录失败 {temp_dir}: {e}", "WARNING")
    
    # 列出最终产物
    log("构建产物:")
    for item in DIST_DIR.iterdir():
        if item.is_file():
            size = item.stat().st_size / (1024 * 1024)
            log(f"  {item.name} ({size:.2f} MB)")
    
    log("构建完成！", "SUCCESS")

# ==================== 主函数 ====================
def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description=f"{PROJECT_NAME} Linux 构建脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python build-linux.py              # Release 构建
  python build-linux.py --debug      # Debug 构建
  python build-linux.py --clean      # 清理构建产物
  python build-linux.py --install    # 安装依赖并构建
        """
    )
    
    parser.add_argument(
        "--debug", 
        action="store_true",
        help="Debug 构建模式（显示控制台输出）"
    )
    parser.add_argument(
        "--clean", 
        action="store_true",
        help="清理构建产物"
    )
    parser.add_argument(
        "--install", 
        action="store_true",
        help="安装依赖并构建"
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"{PROJECT_NAME} Build Script v{VERSION}"
    )
    
    args = parser.parse_args()
    
    # 全局设置
    global DEBUG_MODE
    DEBUG_MODE = args.debug
    
    log_section(f"{PROJECT_NAME} Linux 构建脚本")
    log(f"Python 版本: {sys.version}")
    log(f"构建模式: {'Debug' if DEBUG_MODE else 'Release'}")
    
    # 权限提醒
    log("=" * 60, "INFO")
    log("注意: 如果遇到权限错误或外部管理环境限制，请尝试:", "WARNING")
    log("  1. 使用 sudo 权限运行: sudo python3 build-linux.py", "WARNING")
    log("  2. 或确保已启用 --break-system-packages 支持", "WARNING")
    log("=" * 60, "INFO")
    
    # 清理
    if args.clean:
        clean_build()
        if not (args.install or not args.clean):
            return
    
    # 安装依赖
    if args.install:
        install_dependencies()
    
    # 清理旧构建
    clean_build()
    
    # 检查并安装 PyInstaller（如需要）
    if not check_pyinstaller_installed():
        if not install_pyinstaller():
            log("无法安装 PyInstaller，构建中止", "ERROR")
            sys.exit(1)
    
    # 构建
    success = build_executable()
    
    # 后处理
    if success:
        post_build()
    
    # 返回状态码
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
