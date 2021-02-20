#!/usr/bin python3
# -*- coding: utf-8 -*-

import os
import sys
import openpyxl

def dcmd(cmd):  
    r = os.popen(cmd)  
    text = str(r.read())
    txt = text.rstrip('\n')
    txt = txt.split("  ")
    txt = [x for x in txt if x!=''] 
    r.close()  
    return txt


def platform(folder,path,name):
    '''
    根据数据保存目录的cpuname.conf文件,确定测试机型来选取表格
    '''
    #增加cpu信息确定测试平台
    framework = dcmd("cat %s/cpuname.conf |grep 'Architecture:' |awk '{print $2}'" %(path))
    framework = ",".join(framework)
    print ("cpu架构: %s" %framework)
    if "mips64" == framework:
        mipsname = dcmd("cat %s/cpuname.conf |grep 'Model name:' |awk '{print $5}'" %(path))
        mipsname = ",".join(mipsname)
        if mipsname == "(Loongson-3A3000)":
            cpuname = "3A3000"
        else:
            cpuname = "3A4000"
    else:
        model = dcmd("cat %s/cpuname.conf |grep 'Vendor ID:' |awk '{print $3}'" %(path))
        model = ",".join(model)
        if model == "GenuineIntel":
            cpuname = "Intel"
        elif model == "CentaurHauls":
            cpuname = "zhaoxin"
        elif model == "0x70":
            cpuname = "FT"
        elif model == "0x48":
            cpuname = "kunpeng"
        else:
            print ("未知的cpu架构,测试数据默认会写入intel 表内")
            cpuname = "Intel"

    print ("测试平台: %s" %cpuname)
    sheetname = cpuname
    #拷贝套件内的文件到测试数据所以在的目录
    os.system("cp %s/report/%s %s/" %(folder,name,path))
    #遍历原始表格删除当前平台以外的其他表格信息
    wb = openpyxl.load_workbook("%s/%s" %(path,name))
    ws = wb.active
    sheetname = ws.title
    # for a in wb:
    #     if a is ws:
    #         continue
    #     else:
    #         wb.remove(a)
    # wb.save("%s/%s" %(path,name))

    return sheetname



def getfilename(path):
    filename = os.listdir(path)
    return filename

if __name__ == "__main__":
    pass
