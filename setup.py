from io import open
from setuptools import setup

setup(
    name='BBDown_GUI',
    version='1.0.0',  # 实际版本号，不再是占位符
    url='https://github.com/muwenyan521/BBDown_GUI',
    license='MIT',
    author='之雨',
    description='BBDown using the graphical interface.',
    long_description=''.join(open('README.md', encoding='utf-8').readlines()),
    long_description_content_type='text/markdown',
    keywords=['gui', 'bbdown', 'bilibili', 'download'],
    packages=['BBDown_GUI', 'BBDown_GUI.UI', 'BBDown_GUI.Form'],
    include_package_data=True,
    install_requires=['PyQt5==5.15.6'],
    python_requires='>=3.6',
    classifiers=[
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS',
    ],
    entry_points={
        'console_scripts': [
            'bbdowngui = BBDown_GUI.gui:main',
            'BBDownGUI = BBDown_GUI.gui:main',
            'bbdown_gui = BBDown_GUI.gui:main',
            'BBDown_GUI = BBDown_GUI.gui:main',
        ],
    },
)
