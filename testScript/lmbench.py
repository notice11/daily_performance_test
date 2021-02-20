#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os
import sys
import team
import spo
import writeTables

def lmbench(path,name):
    folder = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sheetname = team.platform(folder,path,name)
    lm_dict = spo.readLmbench(path,resultName)
    #使用list 整合所有的表格名称
    lmlist = ["Processor","BasicInteger","BasicUint64","BasicFloat","BasicDouble","ContextSwitching","CommunicationLatencies","FileVM","CommunicationBandwidths","Memory"]
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[0]],13)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[1]],x+len((lm_dict[lmlist[0]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[2]],x+len((lm_dict[lmlist[1]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[3]],x+len((lm_dict[lmlist[2]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[4]],x+len((lm_dict[lmlist[3]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[5]],x+len((lm_dict[lmlist[4]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[6]],x+len((lm_dict[lmlist[5]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[7]],x+len((lm_dict[lmlist[6]])[0])+2)
    x = writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[8]],x+len((lm_dict[lmlist[7]])[0])+2)
    writeTables.writeLmbench(path,name,sheetname,lm_dict[lmlist[9]],x+len((lm_dict[lmlist[8]])[0])+2)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('\n警告：运行程序需要输入测试数据所在的目录绝对路径 \n请以如下格式重新运行程序:\n\tpython3 lmbench.py /home/uos/logs \n或者 \n\tpython3 lmbench.py /home/uos/fio')
        exit()
    #测试数据所在的目录
    path = sys.argv[1]
    # path = "/home/uos/logs"
    name = "lmbench.xlsx"
    resultName = "summary.out"
    lmbench(path,name)
    