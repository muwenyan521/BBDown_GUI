import sys
import os
import time

def get_workdir():
    if getattr(sys, "frozen", False):
        workdir = os.path.dirname(os.path.abspath(sys.argv[0]))
    else:
        workdir = os.path.dirname(os.path.abspath(__file__))
    return workdir

def get_bbdowndir():
    workdir = get_workdir()
    # 跨平台支持：尝试不同的可执行文件名
    possible_names = ["BBDown.exe", "bbdown.exe", "BBDown", "bbdown"]
    for name in possible_names:
        path = os.path.join(workdir, name)
        if os.path.exists(path):
            return path
    # 如果都没找到，返回默认的Windows名称（向后兼容）
    return os.path.join(workdir, "BBDown.exe")

# 显示图标
# 单文件打包引入外部资源
def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except:
        base_path = get_workdir()
    return os.path.join(base_path, relative_path)

def log(message=''):
    t = time.time()
    return f'[{time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(t))}.{int(t * 1000) % 1000}] - {message}'
