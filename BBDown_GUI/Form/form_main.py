import os
import json

from PyQt5.QtWidgets import QMainWindow, QFileDialog
from PyQt5.QtGui import QPixmap, QIcon

from BBDown_GUI.UI.ui_main import Ui_Form_main
from BBDown_GUI.Form.form_login import FormLogin
from BBDown_GUI.Form.form_output import FormOutput
from BBDown_GUI.Form.form_about import FormAbout
from BBDown_GUI.tool import resource_path, get_workdir, get_bbdowndir

workdir = get_workdir()
bbdowndir = get_bbdowndir()

class FormMain(QMainWindow, Ui_Form_main):
    def __init__(self):
        super(FormMain, self).__init__()
        self.setupUi(self)
        
        self.advanced = False
        self.initialize_ui()
        
        try:
            self.load_config()
        except:
            # 当之前没有保存过任何参数时，界面为默认
            self.resize(620, 400)

    def initialize_ui(self):
        icon = QIcon()
        icon.addPixmap(QPixmap(resource_path("./UI/favicon.ico")), QIcon.Normal, QIcon.Off)
        self.setWindowIcon(icon)
        
        self.lineEdit_ffmpeg.setText(os.path.join(workdir, "ffmpeg.exe"))
        self.lineEdit_aria2c_path.setText(os.path.join(workdir, "aria2c.exe"))
        self.lineEdit_dir.setText(os.path.join(workdir, "Download"))
        self.lineEdit_bbdown.setText(bbdowndir)

        self.pushButton_login.clicked.connect(self.login)
        self.pushButton_logintv.clicked.connect(self.logintv)
        self.pushButton_ffmpeg.clicked.connect(self.ffmpegpath)
        self.pushButton_dir.clicked.connect(self.opendownpath)
        self.pushButton_bbdown.clicked.connect(self.bbdownpath)
        self.pushButton_param.clicked.connect(self.param)
        self.pushButton_download.clicked.connect(self.download)
        self.pushButton_advanced.clicked.connect(self.advanced_toggle)
        self.pushButton_about.clicked.connect(self.about)

    def load_config(self):
        with open(os.path.join(workdir, "config.json"), "r") as f:
            config = json.loads(f.read())

        for item, value in config.items():
            if item == "advanced":
                self.toggle_advanced(value)
            elif isinstance(value, bool):
                getattr(self, item).setChecked(value)
            elif isinstance(value, str):
                getattr(self, item).setText(r"{value}")
            elif isinstance(value, int):
                getattr(self, item).setCurrentIndex(value)

    def toggle_advanced(self, advanced):
        self.advanced = advanced
        if self.advanced:
            self.pushButton_advanced.setText("简易选项<")
            self.resize(1560, 500)
        else:
            self.pushButton_advanced.setText("高级选项>")
            self.resize(620, 400)

    # 登录（网页端）
    def login(self):
        self.win_login = FormLogin("login")
        self.win_login.show()

    # 登录（tv端）
    def logintv(self):
        self.win_login = FormLogin("logintv")
        self.win_login.show()

    # 设置ffmpeg位置
    def ffmpegpath(self):
        filepath, _ = QFileDialog.getOpenFileName(self, "选择文件", os.getcwd(), "ffmpeg (ffmpeg.exe);;All Files (*.*)")
        self.lineEdit_ffmpeg.setText(filepath.replace("/", "\\"))

    # 设置下载目录
    def opendownpath(self):
        if not os.path.exists(self.lineEdit_dir.text()):
            os.makedirs(self.lineEdit_dir.text())
        os.startfile(self.lineEdit_dir.text())

    # 设置BBDown位置
    def bbdownpath(self):
        filepath, _ = QFileDialog.getOpenFileName(self, "选择文件", os.getcwd(), "BBDown (BBDown.exe);;All Files (*.*)")
        self.lineEdit_bbdown.setText(filepath.replace("/", "\\"))
        global bbdowndir
        bbdowndir = self.lineEdit_bbdown.text()

    # 获取下载参数（有返回值）
    def arg(self):
        args = [f'"{self.lineEdit_url.text()}"']

        # 画质选择
        dfn_priority = {
            1: ' --dfn-priority "1080P 高清" ',
            2: ' --dfn-priority "720P 高清" ',
            3: ' --dfn-priority "480P 清晰" ',
            4: ' --dfn-priority "360P 流畅" ',
        }
        if self.radioButton_dfn_more.isChecked() and self.comboBox_dfn_more.currentIndex() != 0:
            dfn = self.comboBox_dfn_more.itemText(self.comboBox_dfn_more.currentIndex())
            args.append(f' --dfn-priority "{dfn}"')
        else:
            args.append(dfn_priority.get(self.radioButton_dfn_priority.isChecked() * 0 + 
                                         self.radioButton_dfn_1080P.isChecked() * 1 + 
                                         self.radioButton_dfn_720P.isChecked() * 2 + 
                                         self.radioButton_dfn_480P.isChecked() * 3 + 
                                         self.radioButton_dfn_360P.isChecked() * 4, ''))

        # 下载源选择
        if self.comboBox_source.currentIndex() != 0:
            choice = ['', '-tv', '-app', '-intl']
            args.append(' ' + choice[self.comboBox_source.currentIndex()] + ' ')

        # 下载视频编码选择
        encoding_priority = ['', 'AVC', 'AV1', 'HEVC']
        if self.comboBox_encoding.currentIndex() != 0:
            args.append(' --encoding-priority ' + encoding_priority[self.comboBox_encoding.currentIndex()] + ' ')

        # 指定FFmpeg路径
        if self.checkBox_ffmpeg.isChecked():
            args.append(f' --ffmpeg-path "{self.lineEdit_ffmpeg.text()}" ')

        # 下载分P选项
        if self.radioButton_p_all.isChecked():
            args.append(' -p ALL ')
        elif self.radioButton_p_new.isChecked():
            args.append(' -p NEW ')

        # 高级选项
        if self.advanced:
            self.add_advanced_options(args)

        # 下载路径
        args.append(f' --work-dir "{self.lineEdit_dir.text()}" ')
        
        return ''.join(args)

    def add_advanced_options(self, args):
        options = {
            "checkBox_audio_only": ' --audio-only ',
            "checkBox_video_only": ' --video-only ',
            "checkBox_sub_only": ' --sub-only ',
            "checkBox_danmaku": ' -dd ',
            "checkBox_ia": ' -ia ',
            "checkBox_info": ' -info ',
            "checkBox_hs": ' -hs ',
            "checkBox_debug": ' --debug ',
            "checkBox_token": f' -token "{self.lineEdit_token.text()}" ',
            "checkBox_c": f' -c "{self.lineEdit_c.text()}" ',
            "checkBox_skip_subtitle": ' --skip-subtitle ',
            "checkBox_skip_cover": ' --skip-cover ',
            "checkBox_skip_mux": ' --skip-mux ',
            "checkBox_skip_ai": ' --skip-ai true ' if self.checkBox_skip_ai.isChecked() else ' --skip-ai false ',
            "checkBox_mp4box": ' --use-mp4box ',
            "checkBox_mp4box_path": f' --mp4box-path "{self.lineEdit_mp4box_path.text()}" ',
            "checkBox_mt": ' -mt true ' if self.checkBox_mt.isChecked() else ' -mt false ',
            "checkBox_force_http": ' --force-http  true ' if self.checkBox_force_http.isChecked() else ' --force-http  false ',
            "checkBox_language": f' --language {self.lineEdit_language.text()} ',
            "checkBox_p_show_all": ' --show-all ' if self.checkBox_p_show_all.isChecked() else '',
            "checkBox_p": f' -p {self.lineEdit_p.text()} ' if self.checkBox_p.isChecked() else '',
            "checkBox_p_delay": f' --delay-per-page {self.lineEdit_p_delay.text()} ' if self.checkBox_p_delay.isChecked() else '',
            "checkBox_use_aria2c": ' --use-aria2c ',
            "checkBox_aria2c_path": f' --aria2c-path "{self.lineEdit_aria2c_path.text()}" ',
            "checkBox_aria2c_proxy": f' --aria2c-proxy {self.lineEdit_aria2c_proxy.text()} ',
            "checkBox_aria2c_args": f' --aria2c-args "{self.lineEdit_aria2c_args.text()}" ',
            "checkBox_F": f' -F "{self.lineEdit_F.text()}" ',
            "checkBox_M": f' -M "{self.lineEdit_M.text()}" ',
            "checkBox_enable_proxy": ''
        }

        for checkBox, arg in options.items():
            if getattr(self, checkBox).isChecked():
                args.append(arg)
            elif checkBox == "checkBox_enable_proxy":
                if self.checkBox_host.isChecked():
                    args.append(f' --host {self.lineEdit_host.text()} ')
                if self.checkBox_ep_host.isChecked():
                    args.append(f' --ep-host {self.lineEdit_ep_host.text()} ')
                if self.checkBox_area.isChecked():
                    args.append(f' --area {self.lineEdit_area.text()} ')

    def param(self):
        args = self.arg()
        self.lineEdit_param.setText(args)

    # 开始下载
    def download(self):
        def Save():
            config = {i: getattr(self, i).isChecked() if i.startswith("checkBox_") or i.startswith("radioButton_") 
                      else getattr(self, i).text() if i.startswith("lineEdit_") 
                      else getattr(self, i).currentIndex() if i.startswith("comboBox_") 
                      else None 
                      for i in dir(self) if (i.startswith("checkBox_") or i.startswith("radioButton_") 
                      or i.startswith("lineEdit_") or i.startswith("comboBox_"))}
            config["advanced"] = self.advanced
            with open(os.path.join(workdir, "config.json"), "w") as f:
                f.write(json.dumps(config, indent=4))

        Save()
        args = self.arg()
        self.win_output = FormOutput(args)
        self.win_output.show()

    # 高级选项
    def advanced_toggle(self):
        self.toggle_advanced(not self.advanced)

    # 关于
    def about(self):
        self.win_about = FormAbout()
        self.win_about.show()
