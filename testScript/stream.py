#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import team
import spo
import writeTables

def stream(path,name):
    folder = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sheetname = team.platform(folder,path,name)
    filelist = os.listdir(path)
    _one,_to = spo.readStream(filelist,path)
    x = writeTables.writeColumn(path,name,sheetname,_one,9)
    writeTables.writeColumn(path,name,sheetname,_to,x+len(_one[0])+2)



if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('\n警告：运行程序需要输入测试数据所在的目录绝对路径 \n请以如下格式重新运行程序:\n\tpython3 lmbench.py /home/uos/logs \n或者 \n\tpython3 lmbench.py /home/uos/fio')
        exit()
    #测试数据所在的目录
    path = sys.argv[1]
    name = "stream.xlsx"
    stream(path,name)
    