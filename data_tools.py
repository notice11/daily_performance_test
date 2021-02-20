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



class Data_tools:

    def __init__(self,path):
        self.path = path
        #迭代读取文件为list,获取文件名
        self.filename = os.listdir(self.path)
    

    @classmethod
    def format(cls,to_list):
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
    @classmethod
    def avg_list(cls,to_list):
        list_avg = np.array(to_list)
        list_avg = list_avg.mean(axis=0)

        return list_avg



    #类方法,传入shell命令获得执行结果
    @classmethod
    def execCmd(cls,cmd):  
        r = os.popen(cmd)  
        text = str(r.read())
        log = text.rstrip('\n')
        log = log.split("  ")
        log = [x for x in log if x!=''] 
        r.close()  
        return log
    

    #采集集设备信息方法
    def device(self):
        #获取安装镜像的日期
        systemdate = Data_tools.execCmd ("cat /etc/product-info")
        print (systemdate)

        #获取操作系统版本
        version = Data_tools.execCmd ("cat /etc/os-version")
        print (version)

        #获取内核版本
        kernel_v = Data_tools.execCmd ("uname -a |awk '{print $4}'")
        print (kernel_v)

        #获取系统架构
        framework = Data_tools.execCmd("dpkg --print-architecture")
        print (framework)

        #获取函数获取cpu型号
        lscpu = Data_tools.execCmd("lscpu | grep -i 'Model name:'")
        lscpu = lscpu[1]

        #获取函数获取内存的大小
        free = Data_tools.execCmd("cat /proc/meminfo |grep MemTotal: ")
        print (free[1:])
        
        return systemdate,version,kernel_v,framework,free


    #采集unixbench数据方法
    def unixbench(self):
        
        #内嵌采集数据的方法,需要传入文件名,返回采集结果
        def unix_list(name):
            #单核心数据采集
            log = Data_tools.execCmd (" cat  %s/%s |grep  -A 12 'System Benchmarks Index Values'" % (self.path,name))
            result = Data_tools.execCmd (" cat  %s/%s |grep  'System Benchmarks Index Score' " % (self.path,name))
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
            unixbench_avg = list(Data_tools.avg_list(list_avg))
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


    #采集iozone数据方法
    def iozone(self):
        #根据读取文件的内存值相加获得的数,判断测试iozone结果为多少G内存的测试结果
        iozoneData = []
        for fn in self.filename:
            if "iozone_" in fn:
                iozoneData.append(fn)

        #使用python 自带的数组函数进行排序
        iozoneData.sort()

        #截取iozone的 7 ~ -7段获得内存的大小
        io_a = []
        for a in iozoneData:
            io_a.append(int(a[7:(len(a)-7)]))

        #更具数组的最大值获得 2倍 内存的值,然后计算 1倍 和 1/2 内存的值
        io_max =  max(io_a)
        io_mem = int(io_max/2)
        io_min = int(io_mem/2)

        #读取xls文件获取测试数据
        def ioz(pate):
            import xlrd
            xlrd = xlrd.open_workbook(pate,formatting_info=True,encoding_override="cp1251")

            sheet = xlrd.sheet_by_index(0)

            #双列表一行数据为一个内嵌数组
            all_info = []
            for i in range(1,sheet.nrows):
                row_info=[]
                for j in range(sheet.ncols):
                    row_info.append(sheet.cell_value(i,j))
                #注意，python以对齐来确定循环的所定义区域
                all_info.append(row_info)

            #截取测试数据
            iod = all_info[4:42:3]

            new3 = []
            for a in iod:
                new3.append(a[1])

            return new3
        #定义3个空数组接收读取文件返回的值
        io_to = []
        io_one = []
        io_half = []

        #双循环,获取9个文件的数据
        for a in range(1,4):
            for b in range(1,4):
                if a == 1 :
                    data = ioz("%s/iozone_%sG_%s.xls" %(self.path,io_max,b))
                    io_to.append(data)
                elif a == 2 :
                    data = ioz("%s/iozone_%sG_%s.xls" %(self.path,io_mem,b))
                    io_one.append(data)
                else:
                    data = ioz("%s/iozone_%sG_%s.xls" %(self.path,io_min,b))
                    io_half.append(data)

        io_to = Data_tools.avg_list(io_to)
        io_one = Data_tools.avg_list(io_one)
        io_half = Data_tools.avg_list(io_half)

        print ("\n %s \n %s \n %s" % (io_to,io_one,io_half))
        #返回结果依次为,2倍内存,1倍内存,1/2倍内存

        return io_to,io_one,io_half


    #采集stream数据方法
    def stream(self):
        #根据读取文件的内存值相加获得的数,判断测试iozone结果为多少G内存的测试结果
        data = []
        for fn in self.filename:
            if "stream_" in fn:
                data.append(fn)
        data.sort()
        
        single = data[0]
        many = data[1]
        
        #截取stream结果的方法
        def stream_list(name):
            log = Data_tools.execCmd (" cat  %s/%s |grep -A 4 'Copy:'|awk '{print $2}'" % (self.path,name))
            result = ((",".join(log).split("\n")))
            result = [x for x in result if x!=''] 
            result = result[0:4],result[4:8],result[8:]
            result = list(result)
            result = Data_tools.format(result)
            print (result)
            print ("=" *50)
            return result

        single = stream_list(single)
        many = stream_list(many)
        #返回stream的值,依次为单线程,多线程
        return single,many

    #采集lmbench数据方法
    def lmbench(self):
        #调用shell命令,通过读取文件获得主机名
        name = Data_tools.execCmd("cat %s/summary.out |awk '{print $1}'|sed -n '13,13p'" %self.path)
        name = ",".join(name)
        #调用shell命令,通过读取文件获得内核版本
        kernel = Data_tools.execCmd("cat %s/summary.out |awk '{print $2$3}'|sed -n '13,13p'" %self.path)
        kernel = ",".join(kernel)

        with open("%s/summary.out" %self.path) as f:
            lmbenlog = [line.rstrip('\n',) for line in f]

        lmbendata = []
        for a in lmbenlog:
            # for b in a:
            #分割列表以空格为单位
            lmdate = a.split(' ')
            # print (lmdate)
            #去除空余的数据
            lmdate = [x for x in lmdate if x!=''] 
            # print (lmdate)
            #赋值追加数据到列表
            lmbendata.append(lmdate)
        
        lm_log = []
        for a in lmbendata:
            if name in a:
                lm_log.append(a[3:])
        

        lm_1 = lm_log[3:6]
        lm_1 = Data_tools.format(lm_1)


        lm_2 = lm_log[6:9]
        lm_2 = Data_tools.format(lm_2)
        lm_2 = list(lm_2)
        if len(lm_2) < 5:
            lm_2.insert(2,0)


        lm_3 = lm_log[12:15]
        lm_3 = Data_tools.format(lm_3)


        lm_4 = lm_log[15:18]
        lm_4 = Data_tools.format(lm_4)


        lm_5 = lm_log[18:21]
        lm_5 = Data_tools.format(lm_5)


        lm_6 = lm_log[21:24]
        lm_6 = Data_tools.format(lm_6)
        lm_6 = list(lm_6)
        if len(lm_6) < 7:
            lm_6.insert(4,0)
            lm_6.insert(6,0)

        
        lm_7 = lm_log[27:30]
        lm_7 = Data_tools.format(lm_7)
        lm_7 = list(lm_7)
        if len(lm_7) < 8:
            lm_7.insert(6,0)


        lm_8 = lm_log[30:33]
        lm_8 = Data_tools.format(lm_8)


        lm_9 = lm_log[33:]
        lm_9 = Data_tools.format(lm_9)
        lm_9 = list(lm_9)
        if len(lm_9) < 6:
            lm_9.append(0)
        
        print (("lmbench_表1:\n %s\n\nlmbench_表2:,\n %s\n\nlmbench_表3:,\n %s\n\nlmbench_表4:,\n %s\n\nlmbench_表5:,\n %s\n\nlmbench_表6:,\n %s\n\nlmbench_表7:,\n %s\n\nlmbench_表8:,\n %s\n\nlmbench_表9:,\n %s\n ") %(lm_1,
        lm_2,lm_3,lm_4,lm_5,lm_6,lm_7,lm_8,lm_9))
        return lm_1,lm_2,lm_3,lm_4,lm_5,lm_6,lm_7,lm_8,lm_9

    #采集unixebnch2D数据方法
    def unixebnch2D(self):
        name = "unixbench2D.log"

        unix2d = Data_tools.execCmd(" cat  %s/%s |grep  '2D Graphics Benchmarks Index Score'" % (self.path,name))
        unix2d = (",".join(unix2d).split("\n"))
        unix2d = (",".join(unix2d).split(","))
        unix2d = unix2d[1::2]
        unix2d_list = []
        for a in unix2d:
            unix2d_list.append(float(a))
        unix2d_avg = np.mean(unix2d_list)
        u2d = []
        u2d.append(unix2d_avg)
        print (u2d)
        return u2d


    #采集glmark2数据方法
    def glmark2(self):
        #根据读取文件 glmark2 获取 文件名
        name = []
        for fn in self.filename:
            if "glmark2.txt" in fn:
                name.append(fn)
        
        name = ",".join(name)

        glmark_log = Data_tools.execCmd("cat %s/%s |grep 'glmark2 Score:'" %(self.path,name))
        glmark_log = ",".join(glmark_log).split("\n")
        glmark_log = ",".join(glmark_log).split(" ")
        glmark_log = glmark_log[2::3]
        glmark_list = []
        for a in glmark_log:
            glmark_list.append(float(a))
        glmark_avg = np.mean(glmark_list)
        gk = []
        gk.append(glmark_avg)
        print (gk)
        return gk

    #采集glxgears数据方法
    def glxgears(self):
        #根据读取文件 glxgears 获取 文件名
        name = []
        for fn in self.filename:
            if "glxgears.log" in fn:
                name.append(fn)
        
        name = ",".join(name)
        glxgears_log = Data_tools.execCmd("cat %s/%s |awk '{print $7}'" %(self.path,name))
        glxgears_log = ",".join(glxgears_log).split("\n")
        glxgears_list = []
        for a in glxgears_log:
            glxgears_list.append(float(a))
        glxgears_avg = np.mean(glxgears_list)

        gs = []
        gs.append(glxgears_avg)
        print (gs)
        return gs

        
    #采集10G文件拷贝数据方法
    def file_cp(self):
        #根据读取文件 glxgears 获取 文件名
        name = []
        for fn in self.filename:
            if "10Gfilecopy.log" in fn:
                name.append(fn)
        
        name = ",".join(name)
        file_log = Data_tools.execCmd("cat %s/%s |sed -n '1,3p'" %(self.path,name))
        file_log = ",".join(file_log).split("\n")
        file_list = []
        for a in file_log:
            file_list.append(float(a))
        file_avg = np.mean(file_list)
        file_10 = []
        file_10.append(file_avg)
        print (file_10)
        return file_10

    #采集fio数据
    def fio(self):
        #获取数据目录下的有文件名，并排序
        self.filename.sort()
        _512iops = []
        _1iops = []
        _512bw = []
        _1bw = []
        #读取fio的数据，筛选条件 "iops="
        for a in self.filename:
            if "512B_" in a:
                # print (a)
                with open("%s/%s" %(self.path,a)) as f:
                    _da = [line.rstrip('\n',) for line in f]
                for aa in _da:
                    if "iops=" in aa:
                        aaa = aa.split(",")
                        _512bw.append(aaa[1])
                        _512iops.append(aaa[2])
            elif "1M_" in a:
                with open("%s/%s" %(self.path,a)) as f:
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

    #邮件推送方法
    @classmethod
    def emale_sed(cla):
        pass



if __name__ == "__main__":
    print ("=" * 50)
    path = "/home/uos/logs"
    # Data_tools.device(path)
    data = Data_tools(path)
    # data.fio()

    # data.device()
    data.unixbench()
    # data.iozone()
    # data.stream()
    # data.lmbench()
    # data.unixebnch2D()
    # data.glmark2()
    # data.glxgears()
    # data.file_cp()