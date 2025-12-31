# BBDown_GUI
BBDown的图形化版本 - 哔哩哔哩(B站)视频下载、音频下载、字幕下载 - bilibili video download

## 屏幕截图

### 简易模式

<img src="https://user-images.githubusercontent.com/29673994/169644975-066c4ac5-7fb1-4361-8c62-bb1e5aba4381.png" height="50%" width="50%" >

### 高级模式

<img src="https://user-images.githubusercontent.com/29673994/200099369-51250aa4-bd7f-4547-864c-f552143adcc1.png">

## 特性

- [x] 记忆下载参数
- [x] 下载剧集选项（当前剧集、全部剧集、最新剧集）
- [x] 优先显示常用选项，亦保留有所有功能
- [x] 下载进度控制

## 使用方法

将 BBDown 的可执行程序与本 UI 程序置于同一文件夹中，直接运行即可。这样以后 BBDown 主程序更新也可以直接替换使用

## 下载

### 从 [Releases](https://github.com/muwenyan521/BBDown_GUI/releases) 中下载使用 [![img](https://img.shields.io/github/v/release/muwenyan521/BBDown_GUI?label=%E7%89%88%E6%9C%AC)](https://github.com/muwenyan521/BBDown_GUI/releases) 

预打包好的二进制文件，包括
- BBDown - GUI (Windows/Linux/macOS)
- BBDown
- FFmpeg
- Aria2c

### 从源码运行使用
```
pip install -r requirements.txt
python -m BBDown_GUI
```

### 构建Linux包 (AppImage/.deb)

#### 构建AppImage
```bash
# 确保已安装必要的依赖
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv fakeroot

# 运行构建脚本
chmod +x build-linux.sh
./build-linux.sh
```

#### 构建.deb包
```bash
chmod +x build-deb.sh
./build-deb.sh
```

### 从[持续集成](https://github.com/muwenyan521/BBDown_GUI/actions/workflows/build.yml)中下载(beta version) [![Pack Python application](https://github.com/muwenyan521/BBDown_GUI/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/muwenyan521/BBDown_GUI/actions/workflows/build.yml)
进入Actions，选择Pack Python application，进入需要下载的工作流
![image](https://github.com/muwenyan521/BBDown_GUI/assets/29673994/d7944b79-ae96-4c6a-9892-f8e7d3238a61)
到下方Artifacts下载BBDown_GUI
![image](https://github.com/muwenyan521/BBDown_GUI/assets/29673994/45c92ba5-80cc-47db-b5cc-8abe23de2078)


## 致谢&License

 - https://github.com/nilaoda/BBDown (MIT License)

<!--

## 相关Repository

 - [BBDown_hk](https://github.com/muwenyan521/BBDown_hk)

-->
