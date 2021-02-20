#!/bin/bash

echo "当前用户是："
whoami

if [ $('whoami') != 'root' ];then
  echo "请使用root用户执行！！!";
  sleep 1
  exit
fi

# 获取平台类型，1为服务器版本，0为桌面版本
PlatForm=`uname -r |grep server|wc -l`
# 获取环境CPU 核数
CPU_N=`cat /proc/cpuinfo |grep processor|wc -l|tr -d "\n"`

#获取CPU架构
SYSARCH=`uname -m`
#获取内存大小
mem_size=`awk '($1=="MemTotal:"){printf  "%0.0f",$2/1024/1024}' /proc/meminfo`

#更正内存大小
function resize_mem(){
    size=1
    while [[ $1 -ge $size ]]; do
        size=`expr $size \* 2`
        if [[ $1 -eq $size ]]; then
            break
        fi
    done
    return $size
}

resize_mem $mem_size

MEM=$?
MEM2=`expr $MEM \* 2`
MEM_2=`expr $MEM / 2`


#获取最大可用容量分区
# data_dir=`df -k|sort -k 4rn,4|head -n 1|awk '{print$6}'`
data_dir=/data

#测试工具下载路径
# netperf_path="https://docs.deepin.com/f/2f7a30c4b6/?raw=1"
# iozone_path="https://docs.deepin.com/f/8b63855b0b/?raw=1"
# unixbench_path="https://docs.deepin.com/f/53f72a06a6/?raw=1"
# stream_path="https://docs.deepin.com/f/12b4067d6a/?raw=1"
# SPECjvm_path="https://docs.deepin.com/f/9bc710aaca/?raw=1"
# ltp2016_path="https://docs.deepin.com/f/75c70488ee/?raw=1"
# ltp2019_path="https://docs.deepin.com/f/1a6be5ab0a/?raw=1"
# glmark_path="https://docs.deepin.com/f/dae84f6687/?raw=1"
# lmbench_path="https://docs.deepin.com/f/8ad5fd0125/?raw=1"
# install_jvm_path="https://docs.deepin.com/f/0ac9932563/?raw=1"
# sysbench_path="https://docs.deepin.com/f/d99de32383/?raw=1"
# fio_path="https://docs.deepin.com/f/a43959eed2/?raw=1"
package_url="https://docs.deepin.com/f/e8cb7e3a16/?raw=1"


# 自启动变量
TESTPATH=/home/uos
run_pwd=$TESTPATH/run.py
run_path=/lib/systemd/system/test.service
run_txt=$TESTPATH/logs/run.txt
run_log=$TESTPATH/logs/run.log
run_conf=$TESTPATH/logs/run.conf
install_txt=$TESTPATH/logs/install.txt

#获取运行配置
run_number=0
if [ -s $run_conf ];then
    run_number=`awk '/run-number/{print $2}' $run_conf`
fi

#获取Fio配置
if [[ $run_number == 2 ]]; then
    Partition=`awk '/fio-partition/{print $2}' $run_conf`
    Size=`awk '/fio-size/{print $2}' $run_conf`
    Threads=`awk '/fio-thread/{print $2}' $run_conf`
    runtime=`awk '/runtime/{print $2}' $run_conf`
fi


#判断命令是否执行成功
function is_success(){
    if [[ $? -ne 0 ]]; then
        echo "$1失败"
        exit
    else
        echo "$1成功"
    fi
}

#获取环境信息
function get_systeminfo(){
    cd $TESTPATH/logs
    FILE_ADD_NAME=`date "+%Y%m%d%H%M%S"`
    LOG_FILE_NAME="./systeminfo-$FILE_ADD_NAME"
    if [ -f $LOG_FILE_NAME ]
    then
        rm $LOG_FILE_NAME
    fi

    function run_cmd_log()
    {
        local cmd="$1"      
        echo " " >> $LOG_FILE_NAME 2>&1
        echo "$cmd " >> $LOG_FILE_NAME 2>&1
        $cmd >> $LOG_FILE_NAME 2>&1
        echo " " >> $LOG_FILE_NAME 2>&1
    }

    function show_file()
    {
        local file_name="$1"
        echo ""
        run_cmd_log "cat $file_name"
    }

    function get_dir_file_echo()
    {
        local target_dir="$1" 
        if [ ! -d $target_dir ]
        then
            echo "DIR $target_dir not exist." >> $LOG_FILE_NAME 2>&1
            return 1
        fi
        for file in `ls $target_dir`
        do
            if [ -d "$target_dir/$file"  ]
            then
                get_dir_file_echo "$target_dir/$file"	
            fi
            if [ -f "$target_dir/$file" ]
            then
                show_file "$target_dir/$file"
            fi	
        done
    }

    run_cmd_log "findmnt"
    run_cmd_log "lsblk"
    run_cmd_log "lsscsi"
    run_cmd_log "ifconfig"
    run_cmd_log "uname -a"
    run_cmd_log "free"
    run_cmd_log "getconf PAGE_SIZE"
    run_cmd_log "swapon -s"
    run_cmd_log "df -Th"
    
    get_dir_file_echo "/sys/block/sda/queue"
    get_dir_file_echo "/sys/block/sdb/queue"
    get_dir_file_echo "/sys/block/sdc/queue"
    get_dir_file_echo "/sys/block/sdd/queue"
    get_dir_file_echo "/sys/block/sde/queue"
    get_dir_file_echo "/sys/block/sdf/queue"
    get_dir_file_echo "/sys/block/sdg/queue"
    get_dir_file_echo "/proc/sys/vm"
    get_dir_file_echo "/proc/sys/fs"
    get_dir_file_echo "/proc/fs"
    
    # ext4
    for disk_info in ` mount | grep ext4 | awk -F " " '{print $1}' ` 
    do
        run_cmd_log "dumpe2fs -h $disk_info"
    done
    
    # xfs
    for mount_dir in ` mount | grep xfs | awk -F " " '{print $3}' `
    do
        run_cmd_log "xfs_info $mount_dir"
    done


}



#设置自动登录并清空秘钥环
function set_autoLogin(){
    dbus-send --system --dest=com.deepin.daemon.Accounts --print-reply /com/deepin/daemon/Accounts/User1000 com.deepin.daemon.Accounts.User.EnableNoPasswdLogin boolean:true
    sleep 1
    dbus-send --system --dest=com.deepin.daemon.Accounts --print-reply /com/deepin/daemon/Accounts/User1000 com.deepin.daemon.Accounts.User.SetAutomaticLogin boolean:true
    sleep 1
    rm -f /home/uos/.local/share/keyrings/*
    sleep 1
}

#关闭自动登录
function off_autoLogin(){
    dbus-send --system --dest=com.deepin.daemon.Accounts --print-reply /com/deepin/daemon/Accounts/User1000 com.deepin.daemon.Accounts.User.EnableNoPasswdLogin boolean:false
    sleep 1
    dbus-send --system --dest=com.deepin.daemon.Accounts --print-reply /com/deepin/daemon/Accounts/User1000 com.deepin.daemon.Accounts.User.SetAutomaticLogin boolean:false
    sleep 1
}


#下载文件，如果不存在或者文件大小为0，则下载,
function download_file(){
    if [[ ! -s $1 ]]; then
        #判断seafile服务是否OK
        seafile_status=`wget --server-response --spider  --quiet https://docs.deepin.com/accounts/login/ 2>&1 |grep HTTP|awk '{print$2}'`
        #seafile_status=`wget --server-response --spider  --quiet https://docs.deepin.com/accounts/login/error 2>&1 |grep HTTP|awk '{print$2}'`
        if [[ $seafile_status != "200" ]]; then
            echo "seafile无法访问，请稍后再试！！！"
            read -p "如需要尝试内网下载，请输入1：" choose
            if [[ $choose == "1" ]]; then
                wget -O $1 ftp://10.20.32.27/package/$1
            else
                exit 
            fi
        fi
        wget -O $1 $2 
    fi
}

#安装glxgears
function install_glxgears(){
    apt install -y mesa-utils
    is_success "安装glxgears"
}

#测试glxgears
function glxgears_test(){
    export  vblank_mode=0 && glxgears >> $TESTPATH/logs/glxgears.log &
    sleep 600
    echo `ps -ef | grep glxgears | grep -v grep | awk '{print $2}' | xargs kill`
}

# 安装x11perf
function install_x11perf(){
    sudo apt -y install x11-apps
    is_success "安装x11perf"
}

#安装netperf
function install_netperf(){
    cd $TESTPATH/package
    # download_file netperf.sh "https://docs.deepin.com/f/96f93fe4ab/?raw=1"
    # download_file netperf-2.7.0.tar.gz $netperf_path
    sleep 1
    #已存在，则删除
    if [[ -d "netperf-20191223" ]]; then
        rm -rf netperf-20191223
    fi
    unrar x netperf-20191223.rar 
    is_success "解压netperf-20191223"
    sleep 1
    cd netperf-20191223
    tar xf netperf-2.7.0.tar.gz
    cd netperf-netperf-2.7.0/
    if [[ $SYSARCH == "aarch64" ]]; then
        ./configure -build=alpha
    else
        ./configure
    fi
    make 
    is_success "编译netperf"
    make install
    is_success "安装netperf"
}

#安装iozone
function install_iozone(){
    cd $TESTPATH/package
    # download_file iozone3_430.tar $iozone_path
    #已存在，则删除
    if [[ -d "iozone3_430" ]]; then
        rm -rf iozone3_430
    fi
    sleep 1
    tar -xvf iozone3_430.tar
    is_success "解压iozone3_430.tar"
    sleep 1
    cd iozone3_430/src/current && make linux
    is_success "安装iozone"
}


#测试iozone  1/2倍
function iozone_half_test(){
    cd $TESTPATH/package/iozone3_430/src/current
    for (( i=1;i<4;i++ ))
        do 
        echo "第$i次执行iozone_half测试" 
        ./iozone -Rb $TESTPATH/logs/iozone_${MEM_2}G_$i.xls  -i 0 -i 1 -i 2  -i 3 -i 4 -i 5 -i 6 -i 7 -r 16M -s  ${MEM_2}g  -f $data_dir/iozone_test_2_$i.file
        is_success "第$i次iozone_half测试"
        sync && echo 3 > /proc/sys/vm/drop_caches
        sleep 70
        done 
}

#测试iozone  1倍
function iozone_one_test(){
    cd $TESTPATH/package/iozone3_430/src/current
    for (( i=1;i<4;i++ ))
        do 
        echo "第$i次执行iozone_one测试" 
        ./iozone -Rb $TESTPATH/logs/iozone_${MEM}G_$i.xls  -i 0 -i 1 -i 2  -i 3 -i 4 -i 5 -i 6 -i 7 -r 16M -s  ${MEM}g  -f $data_dir/iozone_test_$i.file
        is_success "第$i次iozone_one测试"
        sync && echo 3 > /proc/sys/vm/drop_caches
        sleep 70
        done
    
}

#测试iozone  2倍
function iozone_double_test(){
    cd $TESTPATH/package/iozone3_430/src/current
    for (( i=1;i<4;i++ ))
        do 
        echo "第$i次执行iozone_double测试" 
        ./iozone -Rb $TESTPATH/logs/iozone_${MEM2}G_$i.xls  -i 0 -i 1 -i 2  -i 3 -i 4 -i 5 -i 6 -i 7 -r 16M -s  ${MEM2}g  -f $data_dir/iozone_test2_$i.file
        is_success "第$i次iozone_double测试"
        sync && echo 3 > /proc/sys/vm/drop_caches
        sleep 70
        done
    
}


#安装unixbench
function install_unixbench_desktop(){
    cd $TESTPATH/package
    # download_file UnixBench.zip $unixbench_path
    #已存在，则删除
    if [[ -d "UnixBench" ]]; then
        rm -rf UnixBench
    fi
    tar xf UnixBench5.1.3.tgz
    is_success "解压UnixBench.zip"
    #cd UnixBench
    #make
    is_success "安装unixbench"
}

#测试Unixbech桌面
function UnixBench_test_desktop(){
    cd $TESTPATH/package/UnixBench  
    for (( i=1;i<4;i++ ))
        do 
        echo "第$i次执行Unixbench测试" 
        ./Run -c 1 >> $TESTPATH/logs/unixbench_1core.log
        is_success "unixbench 单核测试"
        sleep 10
        sync && echo 3 > /proc/sys/vm/drop_caches
        ./Run -c $CPU_N >> $TESTPATH/logs/unixbench_Ncores.log
        is_success "unixbench 多核测试"
        sync && echo 3 > /proc/sys/vm/drop_caches
        done    
}


#测试Unixbech服务器
function UnixBench_test_server(){
    cd $TESTPATH/package/UnixBench
    ./Run  > $TESTPATH/logs/unixbench.log
    is_success "unixbench 多核测试"
}

#测试Unixbench 2D图形性能
#测试3次，每次测试之前清空缓存
function UnixBench_2Dtest(){
    cd $TESTPATH/package/UnixBench
    sed -i '/"3D Graphics Benchmarks"/d' Run
    sed -i '/"3dinfo | cut -f1 -d"/d' Run
    # ./Run graphics > $TESTPATH/logs/unixbench2D.log1
    for (( i=1;i<4;i++ ))
        do 
        echo "第$i次执行Unixbench 2D 测试" 
        echo `date`
        sync && echo 3 > /proc/sys/vm/drop_caches
        sleep 70
        ./Run graphics >> $TESTPATH/logs/unixbench2D.log
        done
}

#安装stream
function install_stream(){
    cd $TESTPATH/package
    # download_file stream.zip $stream_path
    #已存在，则删除
    if [[ -d "Stream" ]]; then
        rm -rf Stream
    fi
    apt install -y make g++ gfortran
    unzip Stream.zip
    is_success "解压stream.zip"
    # cd Stream
    # # make
    is_success "安装stream"
}



#测试stream
#测试3次，每次测试前清空缓存
function stream_test(){
    cd $TESTPATH/package/Stream
    #用命令获取model name
    model=`lscpu |grep -w "Model name"|awk '{print$3}'`

    #判断机器是否是飞腾,是飞腾执行dmidecode -t cache取缓存值, 其他机器使用lscpu取值，换算成MB
    b=1024
    cache=`lscpu |grep -w "cache"|tail -1|awk '{print$3}'`
    cache1=`echo $cache|sed 's/.$//'`
    cachem=$(expr $cache1 / $b)
    echo "三级缓存单位为MB的值是$cachem"

    #取出cpu核数的值
    #cpus=`cat /proc/cpuinfo |grep "physical id" |sort |uniq| wc -l`
    cpus=1

    #根据公式计算出DSTREAM_ARRAY_SIZE的值
    size=`echo "$cachem * $cpus * 4.1 * 1024 * 1024"|bc`
    size1=`echo "$size/8"|bc`

    sed -i "58s/2000000/$size1/" stream.c

    for (( i=1;i<4;i++ ))
    do
    #单线程
        gcc -O3 -DNTIMES=30  stream.c -o stream
        ./stream >> $TESTPATH/logs/stream_单线程.txt
        echo "结果成功写入单线程.txt"
        sync && echo 3 > /proc/sys/vm/drop_caches

        #满线程
        sleep 30
        gcc -O3 -fopenmp -DNTIMES=30  stream.c -o stream
        ./stream >> $TESTPATH/logs/stream_满线程.txt
        echo "结果成功写入满线程.txt"
        sync && echo 3 > /proc/sys/vm/drop_caches
    done
}

#安装ltp
# function install_ltp(){
#     cd $TESTPATH/package
#     # download_file ltp-full-20160510.tar.bz2 $ltp2016_path
#     # download_file ltp-full-20190930.tar.bz2 $ltp2019_path
#     sleep 3
#     export DEBIAN_FRONTEND=noninteractive
#     apt install -y git autoconf automake m4 make gcc libcap-dev libssl-dev libselinux1-dev libaio-dev libexplain-dev libacl1-dev libtirpc-dev freebsd-glue bison libkeyutils-dev libmm-dev libsctp-dev flex libregf-dev libdts-dev libdtools-ocaml-dev libnuma-dev dma jfsutils xfslibs-dev netconfd numactl numad linux-headers-`uname -r` 
#     #已存在，则删除
#     if [[ -d "ltp-full-20160510" ]]; then
#         rm -rf ltp-full-20160510
#     fi
#     tar -jxvf  ltp-full-20160510.tar.bz2
#     is_success "解压ltp-full-20160510.tar.bz2"
#     cd ltp-full-20160510
#     make autotools
#     is_success
#     ./configure
#     is_success
#     make
#     is_success "编译ltp"
#     make install
#     is_success "安装ltp"
# }

#安装glmark
function install_glmark(){
    cd $TESTPATH/package
    # download_file glmark2.zip $glmark_path
    apt install -y git g++ build-essential pkg-config  libx11-dev libgl1-mesa-dev libjpeg-dev libpng12-dev libudev-dev libgles2-mesa-dev libgbm-dev
    #已存在，则删除
    if [[ -d "glmark2" ]]; then
        rm -rf glmark2
    fi
    unzip glmark2.zip
    cd glmark2/
    #针对麒麟镜像修改编码格式
    sed -i '3a import sys\nreload(sys)\nsys.setdefaultencoding("utf-8")' waflib/Logs.py 
    ./waf configure --with-flavors=x11-gl
    is_success
    ./waf build -j4
    is_success "编译glmark"
    ./waf install
    is_success
    strip -s /usr/local/bin/glmark2
    is_success "安装glmark"
}

#测试glmark
function glmark2_test(){
    cd $TESTPATH
    for (( i=1;i<6;i++ ))
        do echo "第$i次执行glmark2" 
        glmark2 >> logs/glmark2.txt
        sleep 60
        done
}

#安装lmbench
function install_lmbench(){
    cd $TESTPATH/package
    # download_file lmbench.zip $lmbench_path
    #已存在，则删除
    if [[ -d "lmbench" ]]; then
        rm -rf lmbench
    fi
    unrar x lmbench.rar
    cd lmbench
    tar xf lmbench-3.0-a9.tgz
    cp config.guess lmbench-3.0-a9/scripts/gnu-os
    is_success "解压 lmbench3.zip"
    #cd lmbench
    #make
    # is_success "lmbench 安装"
}

#测试lmbench
function lmbench_test(){
    apt install -y expect
    cd $TESTPATH/package/lmbench/lmbench-3.0-a9
    download_file lmbench_test.sh https://docs.deepin.com/f/12ede5a96e/?raw=1
    #判断是否为服务器版本
    if [[ $PlatForm -ne 0 ]]; then
        #是服务器，判断内存大小是否小于16G
        if [[ $MEM -lt 16 ]]; then
            #内存小于16G，内存大小为推荐配置
            sed -i "s/2048//g" lmbench_test.sh
        else
            #内存大于16G，则将2048替换为16384
            sed -i 's/2048/16384/g' lmbench_test.sh
        fi
    fi
    #桌面版本，内存大小为推荐配置
    sed -i "s/2048//g" lmbench_test.sh
    chmod +x lmbench_test.sh
    ./lmbench_test.sh
    echo "开始第1次lmbench测试结束"
    sleep 60
    sync && echo 3 > /proc/sys/vm/drop_caches
    #新增2次测试
    for (( i=1;i<3;i++ ))
    do
        sleep 60
        sync && echo 3 > /proc/sys/vm/drop_caches
        echo "开始第$((i+1))次测试lmbench"
        make rerun
    done
    #echo "开始lmbench测试"
    if [[ $SYSARCH == "x86_64" ]]; then
        sed -i '/^\[mount.*/d' results/x86_64-pc-linux-gnu/uos-PC.*
    elif [[ $SYSARCH == "aarch64" ]]; then
        sed -i '/^\[mount.*/d' results/aarch64-linux-gnu/uos-PC.*
    else
        sed -i '/^\[mount.*/d' results/mips64el-linux-gnu/uos-PC.*
    fi
    make see
    is_success "lmbench 测试"
    cp results/summary.out $TESTPATH/logs/summary.out
    echo "lmbench 日志路径：logs/summary.out"
}

#安装specjvm2008
function install_specjvm(){
    apt install -y expect 
    ver=`java -version 2>&1 |head -n 1|awk '{print$3}'`
    if [[ $ver =~ "1.8.0" ]];then
        echo "jdk版本是1.8"
    else
        apt remove openjdk* -y
        apt --fix-broken install -y
        apt install openjdk-8-* -y
        echo '卸载openjdk,安装jdk1.8!'
    fi
    mips_lib_path="/usr/lib/jvm/java-1.8.0-openjdk-mips64el/lib"
    amd_lib_path="/usr/lib/jvm/java-8-openjdk-amd64/lib"
    arm_lib_path="/usr/lib/jvm/java-1.8.0-openjdk-arm64/lib"
    cd $TESTPATH/package
    download_file install_specjvm.sh $install_jvm_path
    download_file SPECjvm2008_1_01_setup.jar $SPECjvm_path
    download_file ct.sym https://docs.deepin.com/f/4dc9736ca3/?raw=1
    #替换ct.sym文件
    if [[ $SYSARCH == "x86_64" ]]; then
        cp -f ct.sym $amd_lib_path/
    elif [[ $SYSARCH == "aarch64" ]]; then
        cp -f ct.sym $arm_lib_path/
    else
        cp -f ct.sym $mips_lib_path/
    fi
    chmod +x install_specjvm.sh
    if [[ -d "/SPECjvm2008" ]]; then
        echo "SPECjvm 已经安装"
        echo "开始删除SPECjvm"
        rm -rf /SPECjvm2008
        echo "开始重新安装SPECjvm"
        ./install_specjvm.sh
        is_success "SPECjvm 安装"
    else
        echo "开始安装SPECjvm"
        ./install_specjvm.sh
        is_success "SPECjvm 安装"
    fi
}

#测试specjvm
function specjvm_test(){
    cd /SPECjvm2008
    java -jar SPECjvm2008.jar --base
    is_success "specjvm base测试"
    java -jar SPECjvm2008.jar --peak
    is_success "specjvm peak测试"
    tar -zcvf  specjvmLog.tgz results/
    cp specjvmLog.tgz $TESTPATH/logs/specjvmLog.tgz

}

#测试文件拷贝
#测试3次，每次测试开始前清空缓存
function 10Gfilecopy_test(){
	cd $TESTPATH/package
	chmod  u+x 10Gfilecopy_test.sh
	echo "开始10Gfilecopy测试--------"
    for (( i=1;i<4;i++ ))
    do
    	sync && echo 3 > /proc/sys/vm/drop_caches
        sleep 5
        ./10Gfilecopy_test.sh > _10Gfilecopy.log
    	tail -n 1 _10Gfilecopy.log >> $TESTPATH/logs/10Gfilecopy.log
    done
	is_success "10Gfilecopy测试"
    
	echo "10Gfilecopy日志路径：logs/10Gfilecopy.log"
    cat $TESTPATH/logs/10Gfilecopy.log |awk '{sum+=$1}END{print"平均值为："sum/NR}' >> $TESTPATH/logs/10Gfilecopy.log
}

#安装sysbench
function install_sysbench(){
    cd $TESTPATH/package/
    download_file sysbench.tgz $sysbench_path
    #已存在，则删除
    if [[ -d "sysbench" ]]; then
        rm -rf sysbench
    fi
    tar -zxvf sysbench.tgz 
    cd sysbench
    ./autogen.sh
    ./configure --without-mysql
    make -j
    make install
    is_success "sysbench 安装"
}

#测试sysbench
function sysbench_test(){
    cd $TESTPATH/package/sysbench
    sysbench threads --threads=64 --thread-yields=100 --thread-locks=2 run > $TESTPATH/logs/sysbench_threads.log
    sysbench memory --threads=12 --memory-block-size=8K --memory-total-size=40G --memory-access-mode=seq run > $TESTPATH/logs/sysbench_mem_seq.log
    sysbench memory --threads=12 --memory-block-size=8K --memory-total-size=40G --memory-access-mode=rnd run > $TESTPATH/logs/sysbench_mem_rnd.log
    sysbench mutex --threads=12 --mutex-num=1024 --mutex-locks=10000 --mutex-loops=10000 run > $TESTPATH/logs/sysbench_mutex.log
    is_success "sysbench 测试"
}


#卸载分区
function umount_part(){
    if [[ `df |grep $1|wc -l` -ne 0 ]];then
        umount $1
    fi
}

#安装fio
function install_fio(){
    cd $TESTPATH/package/
    # download_file fio-2.1.10.tar.gz $fio_path
    unzip FIO.zip
    cd FIO
    # dpkg -i 
    tar -zxvf fio-2.1.10.tar.gz
    cd fio-2.1.10/
    ./configure
    if [[ $SYSARCH == "x86_64" ]]; then
        sed -i '1i\#include <sys/sysmacros.h>' diskutil.c
        sed -i '1i\#include <sys/sysmacros.h>' blktrace.c
    fi
    make
    make install
    is_success "fio-2.1.10 安装"
}



#fio测试，顺序读
function fio_512B_read1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 512B_read1.log
}

#fio测试，顺序写
function fio_512B_write1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 512B_write1.log
}

#fio测试，随机读
function fio_512B_randread1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 512B_randread1.log
}

#fio测试，随机写
function fio_512B_randwrite1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 512B_randwrite1.log
}

#fio测试，顺序混合读写
function fio_512B_rw1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 512B_rw1.log
}

#fio测试，随机混合读写
function fio_512B_randrw1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 512B_randrw1.log
}

#fio测试，顺序读
function fio_1M_read1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 1M_read1.log
}

#fio测试，顺序写
function fio_1M_write1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 1M_write1.log
}

#fio测试，随机读
function fio_1M_randread1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 1M_randread1.log
}

#fio测试，随机写
function fio_1M_randwrite1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 1M_randwrite1.log
}

#fio测试，顺序混合读写
function fio_1M_rw1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 1M_rw1.log
}

#fio测试，随机混合读写
function fio_1M_randrw1(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 1M_randrw1.log
}

#fio测试，顺序读
function fio_512B_read2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 512B_read2.log
}

#fio测试，顺序写
function fio_512B_write2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 512B_write2.log
}

#fio测试，随机读
function fio_512B_randread2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 512B_randread2.log
}

#fio测试，随机写
function fio_512B_randwrite2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 512B_randwrite2.log
}

#fio测试，顺序混合读写
function fio_512B_rw2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 512B_rw2.log
}

#fio测试，随机混合读写
function fio_512B_randrw2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 512B_randrw2.log
}

#fio测试，顺序读
function fio_1M_read2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 1M_read2.log
}

#fio测试，顺序写
function fio_1M_write2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 1M_write2.log
}

#fio测试，随机读
function fio_1M_randread2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 1M_randread2.log
}

#fio测试，随机写
function fio_1M_randwrite2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 1M_randwrite2.log
}

#fio测试，顺序混合读写
function fio_1M_rw2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 1M_rw2.log
}

#fio测试，随机混合读写
function fio_1M_randrw2(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 1M_randrw2.log
}

#fio测试，顺序读
function fio_512B_read3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 512B_read3.log
}

#fio测试，顺序写
function fio_512B_write3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 512B_write3.log
}

#fio测试，随机读
function fio_512B_randread3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 512B_randread3.log
}

#fio测试，随机写
function fio_512B_randwrite3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 512B_randwrite3.log
}

#fio测试，顺序混合读写
function fio_512B_rw3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 512B_rw3.log
}

#fio测试，随机混合读写
function fio_512B_randrw3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=512B -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 512B_randrw3.log
}

#fio测试，顺序读
function fio_1M_read3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=read -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=read > 1M_read3.log
}

#fio测试，顺序写
function fio_1M_write3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=write -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=write > 1M_write3.log
}

#fio测试，随机读
function fio_1M_randread3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randread -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randread > 1M_randread3.log
}

#fio测试，随机写
function fio_1M_randwrite3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randwrite -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randwrite > 1M_randwrite3.log
}

#fio测试，顺序混合读写
function fio_1M_rw3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=rw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=rw > 1M_rw3.log
}

#fio测试，随机混合读写
function fio_1M_randrw3(){
    cd $TESTPATH/logs
    umount_part $Partition
    fio -filename=$Partition -ioengine=psync -time_based=1 -rw=randrw -direct=1 -buffered＝0 -thread -size=$Size -bs=1M -numjobs=$Threads -iodepth=1 -runtime=$runtime -lockmem=1G -group_reporting -name=randrw > 1M_randrw3.log
}



#安装完第一重启
function first_reboot(){
    echo first_reboot >> $run_txt
    sleep 3
    reboot
}

#统计stream结果
#function stream_log_deal(){
#    cd $TESTPATH/logs
#    if [ -e "stream_c.txt" ];then
#        echo "stream单核整型运算结果：" >> stream.out
#        sed -n '24,27p' stream_c.txt |awk '{print$2}' >> stream.out
#        echo "stream单核浮点型运算结果：" >> stream.out
#        sed -n '22,25p' stream_f.txt |awk '{print$2}'  >> stream.out
#        echo "stream多核整型运算结果：" >> stream.out
#        sed -n '24,27p' stream_c_多核.txt |awk '{print$2}'  >> stream.out
#        echo "stream多核浮点型运算结果：" >> stream.out
#        sed -n '22,25p' stream_f_多核.txt |awk '{print$2}'  >> stream.out
#    fi
#}

#统计图形化测试平均值
function gui_data_deal(){
    cd $TESTPATH/logs
    #统计图形化测试平均值
    if [ -e "unixbench2D.log" ];then
        cat unixbench2D.log |grep Score|awk '{sum+=$6}END{print"unixbench2D平均值：",sum/NR}' >> gui.log
    fi
    if [ -e "glmark2.txt" ];then
        cat glmark2.txt |grep Score|awk '{sum+=$3}END{print"glmark平均值：",sum/NR}' >> gui.log
    fi
    if [ -e "glxgears.log" ];then
        #去掉首行和末行并取平均值
        sed -i '1d;$d' glxgears.log
        cat glxgears.log|awk '{sum+=$7}END{print "glxgears平均值: ", sum/NR}' >> gui.log
    fi
}

#统计stream测试平均值
function stream_data_deal(){
    cd $TESTPATH/logs
    #统计图形化测试平均值
    if [ -e "stream_单线程.txt" ];then
        cat stream_单线程.txt |grep "Copy" | awk '{copy+=$2}END{print"CopyAVG:",copy/NR}'  >> streamAVG_单线程.txt
        sleep 0.2
        cat stream_单线程.txt |grep "Scale" | awk '{scale+=$2}END{print"ScaleAVG:",scale/NR}'  >> streamAVG_单线程.txt
        sleep 0.2
        cat stream_单线程.txt |grep "Add" | awk '{add+=$2}END{print"AddAVG:",add/NR}'  >> streamAVG_单线程.txt
        sleep 0.2
        cat stream_单线程.txt |grep "Triad" | awk '{triad+=$2}END{print"TriadAVG:",triad/NR}'  >> streamAVG_单线程.txt
        sleep 0.2
    fi
    if [ -e "stream_满线程.txt" ];then
        cat stream_满线程.txt |grep "Copy" | awk '{copy+=$2}END{print"CopyAVG:",copy/NR}'  >> streamAVG_满线程.txt
        sleep 0.2
        cat stream_满线程.txt |grep "Scale" | awk '{scale+=$2}END{print"ScaleAVG:",scale/NR}'  >> streamAVG_满线程.txt
        sleep 0.2
        cat stream_满线程.txt |grep "Add" | awk '{add+=$2}END{print"AddAVG:",add/NR}'  >> streamAVG_满线程.txt
        sleep 0.2
        cat stream_满线程.txt |grep "Triad" | awk '{triad+=$2}END{print"TriadAVG:",triad/NR}'  >> streamAVG_满线程.txt
    fi
}

#统计uninbench平均值
function unixbench_data_deal(){
    cd $TESTPATH/logs
    #统计图形化测试平均值
    if [ -e "unixbench_1core.log" ];then
        cat unixbench_1core.log |grep Score|awk '{sum+=$5}END{print"单核平均分：",sum/NR}' >> unixbench_avg.log
    fi
    if [ -e "unixbench_Ncores.log" ];then
        cat unixbench_Ncores.log |grep Score|awk '{sum+=$5}END{print"多核平均：",sum/NR}' >> unixbench_avg.log
    fi
}

#统计fio数据
function fio_data_deal(){
    cd $TESTPATH/logs
    if [[ -f 512B_read.log ]]; then
        echo "512B读写带宽"　> fio.log
        sed -n '7p' 512B_read.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_write.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_rw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 512B_rw.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randread.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randwrite.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randrw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 512B_randrw.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
    
        echo "512B读写次数"　>> fio.log
        sed -n '7p' 512B_read.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_write.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_rw.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 512B_rw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randread.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randwrite.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 512B_randrw.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 512B_randrw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
    
        echo "1M读写带宽"　>> fio.log
        sed -n '7p' 1M_read.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_write.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_rw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 1M_rw.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randread.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randwrite.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randrw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 1M_randrw.log |awk '{print$3}'|awk -F"=" '{print$2}' >> fio.log
    
        echo "1M读写次数"　>> fio.log
        sed -n '7p' 1M_read.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_write.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_rw.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 1M_rw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randread.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randwrite.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '7p' 1M_randrw.log |awk '{print$5}'|awk -F"=" '{print$2}' >> fio.log
        sed -n '17p' 1M_randrw.log |awk '{print$4}'|awk -F"=" '{print$2}' >> fio.log
    fi
}

#桌面性能测试
function desktop_test(){
    if [ $run_number == 1 ];then
        install_list=(install_glxgears install_stream install_x11perf install_netperf install_iozone install_unixbench_desktop install_glmark install_lmbench)
        run_list=(first_reboot UnixBench_test_desktop iozone_half_test iozone_one_test iozone_double_test lmbench_test UnixBench_2Dtest 10Gfilecopy_test glxgears_test glmark2_test stream_test)
    elif [ $run_number == 2 ];then
        t2=`awk '/fio/{print $1}' $run_conf`
        if [ -z "$t2" ];then
            read -p "请输入需要测试的硬盘分区，且文件系统为ext4:（如：/dev/sda5）" partition
            # read -p "请输入需要测试的size大小(2倍内存大小):（如：16G）" size
            # read -p "请输入需要测试的线程数:（如：80）" thread
            echo fio-partition $partition >> $run_conf 
            echo fio-size 36G >> $run_conf
            echo fio-thread 4 >> $run_conf
            echo runtime 120 >> $run_conf
        fi

        install_list=(install_fio)
        run_list=(first_reboot fio_512B_read1 fio_512B_write1 fio_512B_randread1 fio_512B_randwrite1 fio_512B_rw1 fio_512B_randrw1 fio_1M_read1 fio_1M_write1 fio_1M_randread1 fio_1M_randwrite1 fio_1M_rw1 fio_1M_randrw1 fio_512B_read2 fio_512B_write2 fio_512B_randread2 fio_512B_randwrite2 fio_512B_rw2 fio_512B_randrw2 fio_1M_read2 fio_1M_write2 fio_1M_randread2 fio_1M_randwrite2 fio_1M_rw2 fio_1M_randrw2 fio_512B_read3 fio_512B_write3 fio_512B_randread3 fio_512B_randwrite3 fio_512B_rw3 fio_512B_randrw3 fio_1M_read3 fio_1M_write3 fio_1M_randread3 fio_1M_randwrite3 fio_1M_rw3 fio_1M_randrw3 )
    elif [ $run_number == 3 ];then
        t3=`awk '/run-custom-install/{print $1}' $run_conf`
        t4=`awk '/run-custom-test/{print $1}' $run_conf`
        if [ -z "$t4" ] || [ -z "$t4" ] ;then
            read -p $'请输入需要安装的测试工具,并使用逗号分割\n（install_glxgears,install_stream,install_x11perf,install_netperf,install_iozone,install_unixbench_desktop,install_glmark,install_lmbench）' custom_install
            read -p $'请输入需要测试的测试项目,并使用逗号分割\n（first_reboot,stream_test,UnixBench_test_desktop,iozone_half_test,iozone_one_test,iozone_double_test,lmbench_test,UnixBench_2Dtest,10Gfilecopy_test,glxgears_test,glmark2_test)' custom_test
            echo run-custom-install $custom_install >> $run_conf
            echo run-custom-test $custom_test >> $run_conf
        fi

        custom_install=`awk '/run-custom-install/{print $2}' $run_conf | sed "s/,/ /g"`
        custom_test=`awk '/run-custom-test/{print $2}' $run_conf | sed "s/,/ /g"`
        install_list=("$custom_install")
        run_list=("$custom_test")
    else
        echo "获取配置异常，请检查$run_conf"
        exit
    fi

    # 安装
    for l in ${install_list[*]};do
        cat $install_txt |grep $l 
        if [[ $? -ne 0 ]];then
            sleep 1
            $l
            echo $l >> $install_txt
            sleep 1
        else
            echo "$l 已安装"
            continue
        fi
    done

    # 执行测试
    for run_i in ${run_list[*]};do
        echo "已完成以下测试："
        cat $run_txt |grep $run_i
        if [[ $? -ne 0 ]];then
            echo "5分钟之后开始$run_i测试，请等待......."
            sleep 300
            echo "$run_i测试中....."
            echo "$run_i未测试,进行测试"  >> $run_log
            echo "---------------开始$run_i测试，开始时间:---------------" >> $run_log
            echo `date` >> $run_log
            sync&&echo 3  > /proc/sys/vm/drop_caches
            $run_i 2>> $run_log
            echo "---------------结束$run_i测试，结束时间:---------------" >> $run_log
            echo `date` >> $run_log
            echo $run_i >> $run_txt
            echo "$run_i测试完成"
            echo "即将进行重启，测试下一项"
            sleep 10
            reboot
        else
            echo "$run_i测试，跳过，进行下一项"  >> $run_log
            continue
        fi
    done
    gui_data_deal
    stream_data_deal
    unixbench_data_deal
    fio_data_deal
    
    #stream_log_deal
    
    echo "全部测试完成"  >> $run_log
    off_autoLogin
    is_success "关闭自动登录"
    systemctl disable test.service
    rm -rf $run_path
    get_systeminfo
    lscpu > $TESTPATH/logs/cpuname.conf
    cd ${TESTPATH}/data_acquisition
    python3 ${TESTPATH}/data_acquisition/data_main.py $TESTPATH/logs
    echo "请仔细核对各个测试项的数据，特别是stream和lmbench！！！"
    echo "如stream数据异常，请手动执行package目录下的stream_test.sh脚本重新测试"
    echo "如lmbench数据异常，请手动删除package/lmbench/lmbench-3.0-a9/results/平台名称/uos-XX.0中，[mount]开头的行全部删除，再运行make see"
}

#服务器性能测试
# function server_test(){
#     if [ $run_number == 1 ];then
#         install_list=(install_sysbench install_netperf install_iozone install_unixbench install_stream install_lmbench install_specjvm)
#         run_list=(first_reboot sysbench_test stream_test 10Gfilecopy_test UnixBench_test lmbench_test iozone_half_test iozone_one_test iozone_double_test specjvm_test)
#     elif [ $run_number == 2 ];then
#         t2=`awk '/fio/{print $1}' $run_conf`
#         if [ -z "$t2" ];then
#             read -p "请输入需要测试的硬盘分区，且文件系统为ext4:（如：/dev/sda5）" partition
#             # read -p "请输入需要测试的size大小(2倍内存大小):（如：16G）" size
#             # read -p "请输入需要测试的线程数:（如：80）" thread
#             echo fio-partition $partition >> $run_conf 
#             echo fio-size 110G >> $run_conf
#             echo fio-thread 16 >> $run_conf
#             echo runtime 300 >> $run_conf
#         fi

#         install_list=(install_fio)
#         run_list=(first_reboot fio_512B_read fio_512B_write fio_512B_randread fio_512B_randwrite fio_512B_rw fio_512B_randrw fio_1M_read fio_1M_write fio_1M_randread fio_1M_randwrite fio_1M_rw fio_1M_randrw)
#     elif [ $run_number == 3 ];then
#         t3=`awk '/run-custom-install/{print $1}' $run_conf`
#         t4=`awk '/run-custom-test/{print $1}' $run_conf`
#         if [ -z "$t4" ] || [ -z "$t4" ] ;then
#             read -p $'请输入需要安装的测试工具\n（install_sysbench,install_netperf,install_iozone,install_unixbench,install_stream,install_lmbench,install_specjvm,install_fio）' custom_install
#             read -p $'请输入需要测试的测试项目\n（first_reboot,sysbench_test,stream_test,10Gfilecopy_test,UnixBench_test,lmbench_test,iozone_half_test,iozone_one_test,iozone_double_test,specjvm_test）\n (first_reboot,fio_512B_read,fio_512B_write,fio_512B_randread,fio_512B_randwrite,fio_512B_rw,fio_512B_randrw,fio_1M_read,fio_1M_write,fio_1M_randread,fio_1M_randwrite,fio_1M_rw,fio_1M_randrw)' custom_test
#             echo run-custom-install $custom_install >> $run_conf
#             echo run-custom-test $custom_test >> $run_conf
#         fi

#         custom_install=`awk '/run-custom-install/{print $2}' $run_conf | sed "s/,/ /g"`
#         custom_test=`awk '/run-custom-test/{print $2}' $run_conf | sed "s/,/ /g"`
#         install_list=("$custom_install")
#         run_list=("$custom_test")
#         if [[ "$run_list" =~ "fio" ]];then
#             t2=`awk '/fio/{print $1}' $run_conf`
#             if [ -z "$t2" ];then
#                 read -p "请输入需要测试的硬盘分区，且文件系统为ext4:（如：/dev/sda5）" partition
#                 # read -p "请输入需要测试的size大小(2倍内存大小):（如：16G）" size
#                 # read -p "请输入需要测试的线程数:（如：80）" thread
#                 echo fio-partition $partition >> $run_conf 
#                 echo fio-size 110G >> $run_conf
#                 echo fio-thread 16 >> $run_conf
#                 echo runtime 300 >> $run_conf
#             fi
#         fi
#     else
#         echo "获取配置异常，请检查$run_conf"
#         exit
        
#     fi

#     # 安装
#     for l in ${install_list[*]};do
#         cat $install_txt |grep $l 
#         if [[ $? -ne 0 ]];then
#             sleep 5
#             $l
#             echo $l >> $install_txt
#             sleep 5
#         else
#             echo "$l 已安装"
#             continue
#         fi
#     done


#     # 执行测试
#     for run_i in ${run_list[*]};do
#         echo "已完成以下测试："
#         cat $run_txt |grep $run_i
#         if [[ $? -ne 0 ]];then
#             echo "5分钟之后开始$run_i测试，请等待......."
#             sleep 300
#             echo "$run_i测试中....."
#             echo "$run_i未测试,进行测试"  >> $run_log
#             echo "---------------开始$run_i测试，开始时间:---------------" >> $run_log
#             echo `date` >> $run_log
#             sync&&echo 3  > /proc/sys/vm/drop_caches
#             $run_i 2>> $run_log
#             echo "---------------结束$run_i测试，结束时间:---------------" >> $run_log
#             echo `date` >> $run_log
#             echo $run_i >> $run_txt
#             echo "$run_i测试完成"
#             echo "即将进行重启，测试下一项"
#             sleep 10
#             reboot
#         else
#             echo "$run_i测试，跳过，进行下一项"  >> $run_log
#             continue
#         fi
#     done
    
#     echo "全部测试完成"  >> $run_log
#     off_autoLogin
#     is_success "关闭自动登录"
#     systemctl disable test.service
#     rm -rf $run_path
#     get_systeminfo
    
# }

# 主程序
function main_test(){
    #apt update
    #is_success "apt更新"
    set_autoLogin
    is_success "设置自动登录"
    sleep 3
    cd $TESTPATH
    if [[ ! -d logs ]]; then
        mkdir logs
    fi
    if [[ ! -d package ]]; then
        download_file package.zip $package_url
        unzip package.zip
    fi
    if [[ -x $run_path ]];then
        echo "存在自启动"
        # 重新加载配置文件
        systemctl daemon-reload
        systemctl enable test.service
    else
        echo "[Unit]" >> $run_path
        echo "Description=test" >> $run_path
        echo -e "After=network.target\n" >> $run_path
        echo -e "After=lightdm.service\n" >> $run_path
        echo "[Service]" >> $run_path
        echo "Type=simple" >> $run_path
        echo "ExecStart=/usr/bin/python3 $run_pwd" >> $run_path
        echo -e "User=uos\n" >> $run_path
        echo "[Install]" >> $run_path
        echo "WantedBy=multi-user.target" >> $run_path
        chmod 777 $run_path
        # 重新加载配置文件
        systemctl daemon-reload
        systemctl enable test.service
        rm -rf $run_txt
        rm -rf $run_log
        rm -rf $run_conf
        echo "设置自启动成功"
        read -p "请输入需要测试的内容1/2/3（互认证测试/fio测试/自定义）" number
        echo run-number $number >> $run_conf 
        sleep 5
        reboot
    fi
    
    #判断是否为桌面版
    if [[ $PlatForm -ne 0 ]]; then
        server_test
    else
        desktop_test
    fi
}

main_test
