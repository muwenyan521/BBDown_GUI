from pathlib import Path
from BBDown_GUI import gui


def get_resource_path(relative_path):
    """获取跨平台资源路径"""
    base_path = Path(__file__).parent
    return str(base_path / relative_path)


def main():
    gui.main()


if __name__ == '__main__':
    main()

# 打包本文件 (Linux/Mac)
# pyinstaller --noconfirm --onefile --noconsole --icon "./BBDown_GUI/UI/favicon.ico" --add-data "./BBDown_GUI/UI/favicon.ico:./UI" "./build-to-exe.py"
# Windows
# pyinstaller --noconfirm --onefile --noconsole --icon "./BBDown_GUI/UI/favicon.ico" --add-data "./BBDown_GUI/UI/favicon.ico;./UI" "./build-to-exe.py"
