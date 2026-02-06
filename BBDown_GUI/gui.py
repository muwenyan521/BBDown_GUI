import os
import sys
from PyQt5.QtCore import QT_VERSION_STR, Qt
from PyQt5.QtWidgets import QApplication

# High DPI 缩放支持 (必须在 QApplication 创建前设置)
os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "1"
QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)
QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)

from BBDown_GUI.Form.form_main import FormMain

def main():
    app = QApplication(sys.argv)
    win_main = FormMain()
    win_main.show()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
