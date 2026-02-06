import os
import time
import subprocess

from PyQt5.QtWidgets import QMainWindow
from PyQt5.QtGui import QPixmap, QIcon
from PyQt5.QtCore import QThread, pyqtSignal

from BBDown_GUI.UI.ui_qrcode import Ui_Form_QRcode
from BBDown_GUI.tool import get_workdir, get_bbdowndir, resource_path

workdir = get_workdir()

class workthread(QThread):
    signal = pyqtSignal(str)
    def __init__(self, arg):
        super(workthread, self).__init__()
        self.arg = arg
    def run(self):
        for _ in range(181):
            time.sleep(1)
            if (((self.arg == "login") and (os.path.exists(os.path.join(workdir, "BBDown.data")))) or
               ((self.arg == "logintv") and (os.path.exists(os.path.join(workdir, "BBDownTV.data"))))):
                self.signal.emit("登录成功")
                time.sleep(1)
                self.signal.emit("关闭窗口")
                break
            elif os.path.exists(os.path.join(workdir, "qrcode.png")):
                self.signal.emit("请扫描二维码")
            else:
                self.signal.emit("未获取到信息")

class FormLogin(QMainWindow, Ui_Form_QRcode):
    def __init__(self, arg):
        super(FormLogin, self).__init__()
        self.arg = arg
        self.setupUi(self)
        icon = QIcon()
        icon.addPixmap(QPixmap(resource_path("./UI/favicon.ico")), QIcon.Normal, QIcon.Off)
        self.setWindowIcon(icon)
        self.label_QR.setScaledContents(True)
        if (arg == "login") and (os.path.exists(os.path.join(workdir, "BBDown.data"))):
            os.remove(os.path.join(workdir, "BBDown.data"))
        if (arg == "logintv") and (os.path.exists(os.path.join(workdir, "BBDownTV.data"))):
            os.remove(os.path.join(workdir, "BBDownTV.data"))
        env = os.environ.copy()
        env["LANG"] = "C.UTF-8"
        self.p = subprocess.Popen(
            [get_bbdowndir(), self.arg],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=env,
            cwd=workdir,
            universal_newlines=True
        )
        self.execute()
    def execute(self):
        self.work = workthread(self.arg)
        self.work.start()
        self.work.signal.connect(self.display)
    def display(self, s):
        # qrcode.png 保存在应用工作目录
        self.label_QR.setPixmap(QPixmap(os.path.join(workdir, "qrcode.png")))
        self.label.setText(s)
        if s == "关闭窗口":
            self.close()