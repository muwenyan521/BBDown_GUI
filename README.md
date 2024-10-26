# BBDown_GUI：哔哩哔哩视频下载的图形化工具

BBDown_GUI 是 BBDown 的图形化版本，专为哔哩哔哩（B站）视频、音频和字幕的下载而设计。

## 界面预览

### 简易模式
![简易模式](https://user-images.githubusercontent.com/29673994/169644975-066c4ac5-7fb1-4361-8c62-bb1e5aba4381.png)

### 高级模式
![高级模式](https://user-images.githubusercontent.com/29673994/200099369-51250aa4-bd7f-4547-864c-f552143adcc1.png)

## 功能亮点

- **记忆下载参数**：自动保存您的下载偏好，方便下次使用。
- **灵活的剧集下载选项**：支持下载当前剧集、全部剧集或最新剧集。
- **智能界面设计**：常用功能一目了然，同时提供完整的功能访问。
- **下载进度控制**：实时监控和管理您的下载进度。

## 使用指南

将 BBDown 的可执行程序与 BBDown_GUI 放置在同一文件夹中，直接运行即可。这样，即使 BBDown 主程序更新，您也可以直接替换使用。

## 下载方式

### 从 GitHub Releases 下载
[![版本](https://img.shields.io/github/v/release/1299172402/BBDown_GUI?label=版本)](https://github.com/1299172402/BBDown_GUI/releases)
预打包的二进制文件，包括 BBDown - GUI、BBDown、FFmpeg 和 Aria2c。

### 通过 PyPI 安装
[![PyPI 版本](https://img.shields.io/pypi/v/BBDown_GUI)](https://pypi.org/project/BBDown-GUI/)
安装命令：
```bash
pip install BBDown-GUI
```
运行命令（不区分大小写，下划线可省略）：
```bash
BBDown_GUI
```

### 从源码运行
```bash
pip install -r requirements.txt
python -m BBDown_GUI
```

### 从持续集成下载（Beta 版本）
[![打包 Python 应用](https://github.com/1299172402/BBDown_GUI/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/1299172402/BBDown_GUI/actions/workflows/build.yml)
进入 Actions，选择 "Pack Python application"，进入需要下载的工作流，然后在 Artifacts 下载 BBDown_GUI。

## 致谢与许可

- BBDown_GUI 基于 [BBDown](https://github.com/nilaoda/BBDown) 开发，遵循 MIT 许可。
