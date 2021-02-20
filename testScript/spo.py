#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os
import openpyxl
import numpy as np
import xlrd
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header





def format(to_list):
    int_list = []
    for a in to_list:
        new = []
        for b in a:
            if "K" in b:
                tf = b[0:(len(b)-1)]
                new.append(float(tf))
                continue
            new.append(float(b))
        int_list.append(new)
    list_avg = np.array(int_list)
    list_avg = list_avg.mean(axis=0)

    return list_avg

#转换二维数组元素字符为数字,计算二维数组平均值的方法
def avg_list(to_list):
    list_avg = np.array(to_list)
    list_avg = list_avg.mean(axis=0)

    return list_avg




def execCmd(cmd):  
    r = os.popen(cmd)  
    text = str(r.read())
    log = text.rstrip('\n')
    log = log.split("  ")
    log = [x for x in log if x!=''] 
    r.close()  
    return log


#采集集设备信息方法
def device():
    #获取安装镜像的日期
    systemdate = execCmd ("cat /etc/product-info")
    print (systemdate)

    #获取操作系统版本
    version = execCmd ("cat /etc/os-version")
    print (version)

    #获取内核版本
    kernel_v = execCmd ("uname -a |awk '{print $4}'")
    print (kernel_v)

    #获取系统架构
    framework = execCmd("dpkg --print-architecture")
    print (framework)

    #获取函数获取cpu型号
    lscpu = execCmd("lscpu | grep -i 'Model name:'")
    lscpu = lscpu[1]

    #获取函数获取内存的大小
    free = execCmd("cat /proc/meminfo |grep MemTotal: ")
    print (free[1:])
    
    return systemdate,version,kernel_v,framework,free


#采集unixbench数据方法
def unixbench(path):
    
    #内嵌采集数据的方法,需要传入文件名,返回采集结果
    def unix_list(name):
        #单核心数据采集
        log = execCmd (" cat  %s/%s |grep  -A 12 'System Benchmarks Index Values'" % (path,name))
        result = execCmd (" cat  %s/%s |grep  'System Benchmarks Index Score' " % (path,name))
        result = (",".join(result).split("\n"))
        total = []
        for a in result:
            # if "匹配到二进制文件" in a:
            #     continue
            # else:
            total.append(float(a.split(",")[1]))

        logs = []
        for a in log[2::3]:
            if " RESULT" == a:
                continue
            else:
                logs.append(float(a))

        #截取list获得二维数组,一维等于一次结果
        logs = logs[0:12],logs[12:24],logs[24:36]
        logs = list(logs)
        #调用numpy 库函数 计算二维数组的列平均值
        list_avg = np.array(logs)
        unixbench_avg = list(avg_list(list_avg))
        # print (unixbench_avg)

        #添加总分到list的最后
        unixbench_avg.append(np.mean(total))

        #返回读取文件获得的值,类型为list
        print (unixbench_avg)
        print ("=" *50)
        return unixbench_avg

    #定义测试文件的名字
    single = "unixbench_1core.log"
    many = "unixbench_Ncores.log"

    single_avg = unix_list(single)
    many_avg = unix_list(many)

    #依次返回单核结果,多核结果
    return single_avg,many_avg

def readxls(path,filename):
    print(len(filename))
    
    iofile = []
    for fn in filename:
        if ".~iozone" == (fn[0].split("_"))[0] :
            continue
        else:
            if "iozone_" in fn:
                iofile.append(fn)

    print(len(iofile))
    
    #排序以文件命名的的内存值,从大到小
    def dorp(yx):
        return int((yx.split("_"))[1][0:-1])

    iofile.sort(key=dorp,reverse = True)

    # max()获得的数=2倍内存数
    mem_max = int((iofile[0].split("_"))[1][0:-1])
    mem_men = int(mem_max/2)
    mem_min = int(mem_men/2)
    print(mem_max,mem_men,mem_min)

    #总数的 1/3 = 一个阶段的数量
    _count = int(len(iofile)/3)
    _max = iofile[0:_count]
    _men = iofile[_count:_count*2]
    _min = iofile[_count*2:]

    #排序以文件命名的数排序1-30
    def reason(yx):
        return int(",".join(yx.split("_")[2:])[0:-4])
    _max.sort(key=reason)
    _men.sort(key=reason)
    _min.sort(key=reason)

    #定义空list 加入排序好的3阶段数据到空的list
    io_sum = []
    io_sum.append(_max)
    io_sum.append(_men)
    io_sum.append(_min)

    io_list = sum(io_sum,[])

    _io_max = []
    _io_men = []
    _io_min = []
 

    for a in io_list:
        import xlrd
        new = []
        xlrd = xlrd.open_workbook("%s/%s" %(path,a),formatting_info=True,encoding_override="cp1251")
        sheet = xlrd.sheet_by_index(0)
        _mem = int((a.split("_"))[1][0:-1])
        if _mem == mem_max:
            for a in range(5,sheet.nrows,3):
                new.append(sheet.cell_value(a,1))
            _io_max.append(new)
        elif _mem == mem_men:
            for a in range(5,sheet.nrows,3):
                new.append(sheet.cell_value(a,1))
            _io_men.append(new)
        else:
            for a in range(5,sheet.nrows,3):
                new.append(sheet.cell_value(a,1))
            _io_min.append(new)

    return _io_max,_io_men,_io_min




#采集stream数据方法
def readStream(filelist,path):
    #根据读取文件的内存值相加获得的数,判断测试iozone结果为多少G内存的测试结果
    data = []
    for fn in filelist:
        if "stream_" in fn:
            data.append(fn)
    data.sort()

    single = data[0]
    many = data[1]
    
    #截取stream结果的方法
    def stream_list(name):
        log = execCmd(" cat  %s/%s |grep -A 4 'Copy:'|awk '{print $2}'" % (path,name))
        result = ((",".join(log).split("\n")))
        result = [x for x in result if x!=''] 
        print(len(result)/4)
        _stream = np.array(result).reshape(int(len(result)/4),4)
        return _stream

    single = stream_list(single)
    many = stream_list(many)
    #返回stream的值,依次为单线程,多线程
    return single,many



def readLmbench(path,name):
    
    titel = execCmd("cat %s/%s |sed -n '13,13p'|awk '{print $1}'" %(path,name))
    titel = ",".join(titel)
    with open("%s/%s" %(path,name)) as f:
        lmbenlog = [line.rstrip('\n',) for line in f]

    # print(lmbenlog)
    lmbendata = []
    for a in lmbenlog:
        # for b in a:
        #分割列表以空格为单位
        lmdate = a.split(' ')
        #去除空余的数据
        lmdate = [x for x in lmdate if x!=''] 
        #赋值追加数据到列表
        lmbendata.append(lmdate)
        # print(lmdate)

    lm_log = []
    for a in lmbendata:
        if titel in ",".join(a):
            lm_log.append(a[3:])
            # print(a[3:])

    #总长度/标数量12 = 数据的轮次
    number = int(len(lm_log)/12)
    
    #使用字典接收分割出的数据
    lmdata = {
        "Processor": lm_log[number:number*2],
        "BasicInteger":lm_log[number*2:number*3],
        "BasicUint64":lm_log[number*3:number*4],
        "BasicFloat":lm_log[number*4:number*5],
        "BasicDouble":lm_log[number*5:number*6],
        "ContextSwitching":lm_log[number*6:number*7],
        "CommunicationLatencies":lm_log[number*7:number*8],
        "FileVM":lm_log[number*9:number*10],
        "CommunicationBandwidths":lm_log[number*10:number*11],
        "Memory":lm_log[number*11:]
    }

    
    
    lm_proc = []
    for a in lmdata["Processor"]:
        new = []
        for  b in a[1:]:
            new.append(b)
        lm_proc.append(new)

    lmdata["Processor"] = lm_proc
    #为空数据补充,值=0
    for aa in lmdata["BasicInteger"]:
        if len(aa) < 5 :
            aa.insert(2,0)

    for aa in lmdata["BasicUint64"]:
        if len(aa) < 4 :
            aa.insert(1,0)
            aa.insert(2,0)
        elif len(aa) < 5:
            aa.insert(1,0)

    for aa in lmdata["CommunicationLatencies"]:
        if len(aa) < 7 :
            aa.insert(4,0)
            aa.insert(6,0)
    
    for aa in lmdata["FileVM"]:
        if len(aa) < 8 :
            aa.insert(6,0)
    
    for aa in lmdata["Memory"]:
        if len(aa) < 8 :
            aa.append(0)

    # for a in lmlist:
    #     print("=="*50)
    #     print(lmdata[a])

    return lmdata



def readfilename(filelist,name):
    filename = []
    for a in filelist:
        if name in a:
            filename.append(a)
    print(filename[0])
    if len(filename) > 1:
        return filename
    else:
        return filename[0]


def readGlmake2(path,filename,name):
    glmake2 = execCmd("cat %s/%s |grep 'glmark2 Score:' " %(path,filename))
    glk = (",".join(glmake2).split("\n"))
    glmk = ",".join(glk).split(" ")[2::3]
    _glmk = [float(i) for i in glmk]
    return _glmk



def readGlxgears(path,filename,name):
    glxgears = execCmd("cat %s/%s |awk '{print $7}'" %(path,filename))
    glx = (",".join(glxgears).split("\n"))[0:30]
    gl = [float(i) for i in glx]
    return gl



def readUnixbench2D(path,filename,name):
    unixbench2D = execCmd("cat %s/%s |grep '2D Graphics Benchmarks Index Score' " %(path,filename))
    unix2 = ",".join(unixbench2D).split("\n")
    un2 = ",".join(unix2).split(",")
    _un2 = un2[1::2]
    _un = [float(i) for i in _un2]
    return _un



def readCopyfile(path,filename,name):
    copyfile = execCmd("cat %s/%s" %(path,filename))
    file = ",".join(copyfile).split("\n")
    _file = file[:-1]
    cpfile = [float(i) for i in _file]
    return cpfile


#采集fio数据
def fio(filename,path):
    #获取数据目录下的有文件名，并排序
    filename.sort()
    _512iops = []
    _1iops = []
    _512bw = []
    _1bw = []
    #读取fio的数据，筛选条件 "iops="
    for a in filename:
        if "512B_" in a:
            # print (a)
            with open("%s/%s" %(path,a)) as f:
                _da = [line.rstrip('\n',) for line in f]
            for aa in _da:
                if "iops=" in aa:
                    aaa = aa.split(",")
                    _512bw.append(aaa[1])
                    _512iops.append(aaa[2])
        elif "1M_" in a:
            with open("%s/%s" %(path,a)) as f:
                _da1 = [line.rstrip('\n',) for line in f]
            for bb in _da1:
                if "iops=" in bb:
                    bbb = bb.split(",")
                    _1bw.append(bbb[1])
                    _1iops.append(bbb[2])
    #显示数据长度24，3轮测试数据，18 + 2*3 =24
    print ("\n512B_bw长度:%s\n\n512B_iops长度:%s\n\n1M_bw长度:%s\n\n1M_ips长度:%s\n" %(len(_512bw),len(_512iops),len(_1bw),len(_1iops)))

    def clear_(fio_list):
        data = []
        for a in fio_list:
            if a[0:4] == " bw=":
                if a[-4:] == "MB/s":
                    data.append((float(a[4:len(a)-4]))*1024)
                else:
                    data.append(float(a[4:len(a)-4]))
            elif a[0:6] == " iops=":
                data.append(float(a[6:]))
            # print (a)
        return data

    _512_bw = clear_(_512bw)
    _512_iops = clear_(_512iops)
    _1_bw = clear_(_1bw)
    _1_iops = clear_(_1iops)
    print ("=" *50)
    print ("原始数据\n_512_bw:\n%s \n_512_iops:\n%s \n_1_bw:\n%s \n_1_iops:\n%s " %(_512_bw,_512_iops,_1_bw,_1_iops))

    def division (_list):
        a = _list
        #randread  随机读    
        randred = a[0:3]
        randred = np.mean(randred)
        #randrw    随机读写
        randrw = a[3:9:2]
        randrw = np.mean(randrw)
        randrw1 = a[4:9:2]
        randrw1 = np.mean(randrw1)
        #randwrite  随机写
        randwrite = a[9:12]
        randwrite = np.mean(randwrite)
        #read       顺序读
        read = a[12:15]
        read = np.mean(read)
        #rw         顺序读写
        rw = a[15:21:2]
        rw = np.mean(rw)
        rw1 = a[16:21:2]
        rw1 = np.mean(rw1)
        #write        顺序写
        write = a[21:]
        write = np.mean(write)
        list_sort = [read,write,rw,rw1,randred,randwrite,randrw,randrw]

        return list_sort
    _512_rw = division (_512_bw)
    _512_io = division (_512_iops)
    _1_rw = division (_1_bw)
    _1_io = division (_1_iops)
    print ("=" *50)
    print ("\n写表数据\n_512_bw:\n%s \n_512_iops:\n%s \n_1_bw:\n%s \n_1_iops:\n%s " %(_512_rw,_512_io,_1_rw,_1_io))
    #依次返回512B的读写,iops,1M的读写,iops
    return _512_rw,_512_io,_1_rw,_1_io




if __name__ == "__main__":
    path = "/home/uos/fiologs"
    filelsit = os.listdir(path)
    readxls(path,filelsit)