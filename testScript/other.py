#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import spo
import writeTables
def other(path,filelist):
    testList = ["glmark2","glxgears","unixbench2D","10Gfilecopy"]
    filename = spo.readfilename(filelist,testList[0])
    glmark2 = spo.readGlmake2(path,filename,testList[0])

    filename = spo.readfilename(filelist,testList[1])
    glxgears = spo.readGlxgears(path,filename,testList[1])

    filename = spo.readfilename(filelist,testList[2])
    unixbench2D = spo.readUnixbench2D(path,filename,testList[2])

    filename = spo.readfilename(filelist,testList[3])
    copyfile = spo.readCopyfile(path,filename,testList[3])
    
    name = "stream.xlsx"
    sheetname = "stream"

    x = writeTables.writeLine(path,name,sheetname,glmark2,3)
    x = writeTables.writeLine(path,name,sheetname,glxgears,x+1)

    x = writeTables.writeLine(path,name,sheetname,unixbench2D,x+1)

    writeTables.writeLine(path,name,sheetname,copyfile,x+1)
     

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('\n stream,glxgears,unixbench2D,Glmark2,10Gfilecopy 处理脚本 \n警告：运行程序需要输入测试数据所在的目录绝对路径 \n请以如下格式重新运行程序:\n\tpython3 other.py /home/uos/logs \n或者 \n\tpython3 other.py /home/uos/fio')
        exit()
    #测试数据所在的目录
    path = sys.argv[1]
    # path = "/home/uos/logs"
    filelist = os.listdir(path)
    other(path,filelist)
    # name = "stream.xlsx"
    # sheetname = "stream"
    # print("="*100)
    # x = writeTables.writeLine(path,name,sheetname,a,3)
    # x = writeTables.writeLine(path,name,sheetname,b,4)
    # x = writeTables.writeLine(path,name,sheetname,c,x+1)
    # writeTables.writeLine(path,name,sheetname,d,x+1)
    # print("="*100)

    


