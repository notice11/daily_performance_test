#!/usr/bin python3
# -*- coding: utf-8 -*-
import time
import os

print(
    """
    #readme
    #1 操作系统安装用户名为uos，密码1
    #2 将脚本放在/home/uos/下
    #3 设置帐号自动登录，无密码登录(脚本已实现)
    #4 设置电源管理设置关闭显示器、进入待机时间、自动锁屏时间设置成从不，保证显示屏常亮
    #5 窗口特效为默认值
    #6 切换为root账号，执行：python3 run.py
    #7 执行过程中不做任何其他操作...
    """
    )

time.sleep(60)

os.environ['DISPLAY'] = ':0'
os.system("apt update")
os.system("apt install python3-pip libjpeg-dev zlib1g-dev -y")
all = os.popen("pip3 list").read()
if "PyAutoGUI" in all:
    print("存在 PyAutoGUI 库")
else:
    print("不存在 PyAutoGUI 库")
    os.system("pip3 install pyautogui xlrd xlwt -i https://pypi.douban.com/simple/")

# 安装必要库
os.system("apt-get install python3-tk -y")
listdir=os.listdir("/home/uos/")
if "PerformanceTest_reboot.sh" in listdir:
    print("存在 PerformanceTest_reboot.sh 脚本")
else:
    print("不存在 PerformanceTest_reboot.sh 脚本")
    os.system("wget -O /home/uos/PerformanceTest_reboot.sh https://docs.deepin.com/f/65dca015e5/?raw=1")
time.sleep(5)
os.system("chmod 777 /home/uos/PerformanceTest_reboot.sh")
os.system("chmod 777 /home/uos/run.py")

#不能将这个import移动到文件开头！！！
import pyautogui
pyautogui.FAILSAFE = True
# 打开终端
pyautogui.hotkey("ctrl", "alt","t")
time.sleep(10)
# 输入内容
pyautogui.typewrite(message="sudo su", interval="0.25")
time.sleep(2)
pyautogui.press("enter", interval=0.25)
time.sleep(2)
pyautogui.typewrite(message="1", interval="0.25")
time.sleep(2)
pyautogui.press("enter", interval=0.25)
time.sleep(2)
pyautogui.typewrite(message="bash /home/uos/PerformanceTest_reboot.sh", interval="0.25")
time.sleep(2)
# 回车运行
pyautogui.press("enter", interval=0.25)
