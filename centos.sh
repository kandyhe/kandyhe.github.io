#############################################################
# File Name: system.sh
# Author: Hermoso
# E-mail: shenzhuang@aliyun.com
# Created Time: Fri 18 Oct 2018 05:01:02 PM CST
#==================================================================
#!/bin/sh
# 运行环境CentOS 7.x

echo "判断centos7还是centos6系统"
sleep 1
VERSION=`cat /etc/redhat-release|awk -F " " '{print $3}'|awk -F "." '{print $1}'`
if [ "$VERSION" == "6" ];then
VERSION='6'
echo "centos6"
else
VERSION='7'
echo "centos7"
fi

echo "查看内存 cpu 硬盘大小"
sleep 1
MEM=`free -m`
#4.1查看物理CPU个数
physical_id=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
#4.2查看每个物理CPU中core的个数(即核数)
cpu_cores=`cat /proc/cpuinfo| grep "cpu cores"| uniq`
#4.3查看逻辑CPU的个数
processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
echo "$MEM"
echo "####################################################"
echo "cpu物理个数 physical_id:          $physical_id"
echo "每个cpu中core的个数(即核数)       $cpu_cores"
echo "逻辑cpu的个数 processor:          $processor"
echo "####################################################"
#4.4硬盘大小
disk=`df -Th`
echo "$disk"

echo "下载wget，请稍后·······"
yum -y install wget   &>/dev/null

echo "添加DNS地址，请稍等....... "
cat >> /etc/resolv.conf << EOF
nameserver 114.114.114.114 
nameserver 114.114.114.114 
EOF

echo "是否换成阿里云的的源 "
echo "等待3秒:"
sleep 3
cat << EOF
        **********************
        1.[change aliyuan]
        2.[no change aliyuan]
        3.[exit]
    pls input the num you want:
        **********************
EOF
read -t 30 -p "pls input the num you want:" a
[ -n "`echo $a|sed 's#[0-9]##g'`" ] && {
         echo "Input error"
        exit 1
}
iffuncation(){
if [ $a -eq 1 ];then
        echo "change aliyuan"
        echo "等待3S"
        sleep 3
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup   &>/dev/null
        if [ "$VERSION" == "7" ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo   &>/dev/null
        else
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo   &>/dev/null
        fi
        yum clean all    &>/dev/null
        yum makecache    &>/dev/null
        echo "等待3S" 
        sleep 3
elif [ $a -eq 2 ];then
        echo "no change aliyuan"
elif [ $a -eq 3 ];then
        exit 1
else
        echo "Input error"
        exit 1
fi
}
iffuncation

echo "下载必要的初始化的工具"
        sleep 3
        yum -y install net-tools tree nmap lrzsz dos2unix telnet screen vim lsof wget ntp rsync   &>/dev/null

echo "修改ip和主机名的对应关系 /etc/hosts"
        sleep 3
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
if [ "$VERSION" == "7" ];then
        echo "`ifconfig|sed -n '2p'|awk -F " " '{print $2}'` $HOSTNAME" >> /etc/hosts
else
        echo "`ifconfig|sed -n '2p'|awk -F " " '{print $2}'|awk -F ":" '{print $2}'` $HOSTNAME" >> /etc/hosts
fi

echo "查看时间 并设置初始化时间"
date +%F\ %T
ntpdate cn.pool.ntp.org && hwclock -w

echo "命令补全,请稍等....... "
yum install bash-completion -y &>/dev/null

echo "/设置linux的最大文件打开数"
ulimit -SHn 65535
ulimit -a
if [ "`egrep "* - nofile 65535|* - nproc 65536" /etc/security/limits.conf|wc -l`" == "0" ];then
        echo "* - nofile 65535" >> /etc/security/limits.conf
        echo "* - nproc 65536" >> /etc/security/limits.conf
else
        echo "linux的最大文件打开数 设置成功或者之前已经设置过了"
fi
sleep 2

echo "禁用selinux,请稍等......."
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

echo "关闭防火墙,请稍等......."
systemctl disable firewalld.service   &>/dev/null
systemctl stop firewalld.service

echo "优化ssh服务,请稍等......."
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd.service

echo "-------<内核参数优化>-------"
cat >> /etc/sysctl.conf << EOF
vm.overcommit_memory = 1 #表示内核在分配内存时候做检查的方式
net.ipv4.ip_local_port_range = 1024 65536 #端口范围 1024~65535
net.ipv4.tcp_fin_timeout = 1 #保持在FIN-WAIT-2状态的时间
net.ipv4.tcp_keepalive_time = 1200 # TCP发送keepalive消息间隔时间（秒）
net.ipv4.tcp_mem = 94500000 915000000 927000000 #tcp整体缓存设置，对所有tcp内存使用状况的控制，单位是页，依次代表TCP整体内存的无压力值、压力模式开启阀值、最大使用值
net.ipv4.tcp_tw_reuse = 1 # 开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭
net.ipv4.tcp_tw_recycle = 1 # 开启重用，允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_timestamps = 0 # 关闭时间戳 “异常”的数据包
net.ipv4.tcp_synack_retries = 1 # 内核放弃连接之前发送SYN+ACK 包的数量
net.ipv4.tcp_syn_retries = 1 # 内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_abort_on_overflow = 0 #一个布尔类型的标志，控制着当有很多的连接请求时内核的行为
net.core.rmem_max = 16777216 # 指定了接收套接字缓冲区大小的最大值（以字节为单位）
net.core.wmem_max = 16777216 # 指定了发送套接字缓冲区大小的最大值（以字节为单位）
net.core.netdev_max_backlog = 262144 # 允许送到队列的数据包的最大数目
net.core.somaxconn = 262144 #系统中最多有多少个TCP 套接字不被关联到任何一个用户文件句柄上
net.ipv4.tcp_max_orphans = 3276800 #为了防止简单的DoS ***，不能过分依靠它
net.ipv4.tcp_max_syn_backlog = 262144 #表示SYN队列的长度
net.core.wmem_default = 8388608 #指定发送套接字缓冲区大小的缺省值（以字节为单位）
net.core.rmem_default = 8388608 #指定接收套接字缓冲区大小的缺省值（以字节为单位）
#net.ipv4.netfilter.ip_conntrack_max = 2097152 #最大内核内存中netfilter可以同时处理的“任务”（连接跟踪条目）
#net.nf_conntrack_max = 655360 #允许最大跟踪连接条目
#net.netfilter.nf_conntrack_tcp_timeout_established = 1200 # established的超时时间
EOF
/sbin/sysctl -p
echo "系统已优化完毕，请使用！"
