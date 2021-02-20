# 性能测试

## 1. 手动拷贝 testScript下的 "PerformanceTest_reboot.sh" 和 "run.py" 文件到/home/uos下
    
    root用户执行:
        python3 run.py
        
    1 设置电源 不息屏
    2 为需要测试的版本更换仓库,以1030为例
        更换仓库,仓库地址为 http://10.20.12.228/uos-professional/image-sp3/20201125-rc/sources.list 
        中的仓库(如为以发布版本不用更换仓库)
        deb [allow-insecure=yes] http://pools.corp.deepin.com/desktop-professional eagle main contrib non-free
        deb [allow-insecure=yes] http://pools.corp.deepin.com/ppa/dde-eagle eagle/sp3 main contrib non-free
    3 更换内核使用apt安装时, 若报内核依赖错误
        使用 apt --fix-broken install 进行依赖修复
    4 apt  install python3-pip
    5 /home/uos 下执行 python3 run.py
    
    自定义执行单个测试修改 "PerformanceTest_reboot.sh"文件的1065 行的 desktop_test() 函数
    install_list 为需要安装的工具
    run_list 为需要执行的测试
    
## 2. 使用 run_data.sh 运行性能测试加数据采集
    
    root用户执行: 
        bash run_data.sh
    
# 数据处理

## 1. 运行前需要安装python库 :


    pip install xlrd openpyxl numpy


## 2. 数据处理:


    prthon3 data_main.py 测试数据存放的绝对路径
    例如：
        python3 data_main.py /home/uos/logs
        python3 data_main.py /home/uos/fio


## 3. 写入的列数：

    数据默认写入表格的第 5 列
    如需要更换写入的行数，修改 data_main.py 文件 147行

        da.y = 5
        
## 4. 运行测试套件:
    
    root 用户执行:
        bash run_data.sh