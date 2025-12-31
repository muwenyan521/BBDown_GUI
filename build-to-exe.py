from BBDown_GUI import gui

def main():
    gui.main()

if __name__ == '__main__':
    main()

# 打包本文件
# pyinstaller --noconfirm --onefile --noconsole --icon "./BBDown_GUI/UI/favicon.png" --add-data "./BBDown_GUI/UI/favicon.png;./UI"  "./build-to-exe.py"