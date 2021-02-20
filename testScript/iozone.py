#!/usr/bin/python3
# -*- coding: utf-8 -*-

#10.20.32.124

import os
import sys
import team
import spo
import writeTables
def iozone(path,name):
    folder = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sheetname = team.platform(folder,path,name)
    filename = team.getfilename(path)
    mem_3,mem_2,mem_1 = spo.readxls(path,filename)
    x = writeTables.writeColumn(path,name,sheetname,mem_3,13)
    x = writeTables.writeColumn(path,name,sheetname,mem_2,x+15)
    writeTables.writeColumn(path,name,sheetname,mem_1,x+15)



if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('\n警告：运行程序需要输入测试数据所在的目录绝对路径 \n请以如下格式重新运行程序:\n\tpython3 iozone.py /home/uos/logs \n或者 \n\tpython3 iozone.py /home/uos/fio')
        exit()
    #测试数据所在的目录
    path = sys.argv[1]
    name = "iozone.xlsx"
    iozone(path,name)



