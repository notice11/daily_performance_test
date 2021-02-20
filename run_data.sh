#!/bin/bash


#判断执行的用户是否为root
if [ "$(whoami)" = "root" ]
then
    #输出提示语，并将提示语颜色设置为紫色
    echo -e "\\033[35m \\n 数据采集准备中  \\033[0m"
	sleep 1
	echo -e "\\033[35m \\n 请稍后选择测试内容  \\n  \\033[0m"
	sleep 1
else
	echo -e "\\033[35m \\n 执行脚本需要root用户 \\n \\033[0m"
    exit
fi

cd /home/uos/

path=$(pwd) 
#使用kms内网激活
echo -e "\\033[35m \\n 使用kms执行内网激活 \\n \\033[0m"
uos-activator-cmd -s --kms kms.uniontech.com:8900:Vlc1cGIyNTBaV05v

# echo -e "\\033[35m \\n 加入内网仓库 \\n \\033[0m"
# sleep 1
# echo  "deb [allow-insecure=yes] http://pools.corp.deepin.com/desktop-professional eagle main contrib non-free"  > /etc/apt/sources.list
# echo  "deb [allow-insecure=yes] http://pools.corp.deepin.com/ppa/dde-eagle eagle/sp3 main contrib non-free"  >>  /etc/apt/sources.list

echo -e "\\033[35m \\n 更新仓库 \\n \\033[0m"
apt update
echo -e "\\033[35m \\n 安装依赖包 \\n \\033[0m"

#安装依赖包
apt install  -y git python3-pip libjpeg-dev zlib1g-dev
while [ $? = 1 ]
do  
    apt --fix-broken install -y
    apt install -y git python3-pip libjpeg-dev zlib1g-dev
done

#python库
pip3 install openpyxl  xlrd numpy 
while [ $? = 2 ]
do  
    pip3 install install  openpyxl  xlrd numpy
done

echo -e "\\033[35m \\n 组件包安装成功..  \\n  \\033[0m"


if [ ! -d "data_acquisition" ]; then
    echo -e "\\033[35m \\n 下载测试套件  \\n  \\033[0m"
    git clone https://gitlabwh.uniontech.com/ut000253/data_acquisition.git
fi

chmod 777 -R ${path}/data_acquisition/
cp ${path}/data_acquisition/testScript/PerformanceTest_reboot.sh ${path}
cp ${path}/data_acquisition/testScript/run.py ${path}
python3 ${path}/run.py
