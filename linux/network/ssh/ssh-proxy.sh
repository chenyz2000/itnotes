#!/bin/bash
set -e #u
unalias -a
#ssh proxy ， remote port forwarding
#Author: copyright @ Levinit

#only for linux below 3 lines
# script_dir_path=$(dirname $(readlink -f "$0"))
# scirpt_name=$(echo $0 | awk -F '/' '{print $NF}')
script_path=$(readlink -f "$0")

#--log file
log=./proxy.log   #proxy log
log_maxsize=10000 #Bytes

#--remote host as a proxy server 远程主机作为代理服务器
remoteHost=''    #remote host addr
remotePort=22    #remote host sshd port 远程主机的sshd端口
remoteUser=proxy #user on remote host 远程主机上的用户
proxyPort=5509   #remote host forward port, normal users could only use ports above 1024 普通用户只能使用1024以上端口

#--local host (this host which excutes this script) 本地主机（执行这个脚本的主机）
#todo 还可以考虑支持其他主机 目前是转让本机端口 可以转发其他主机端口到proxy主机
localHost=localhost         #this host, IP or host name
localPort=22                #local host sshd port 地主机sshd端口
localUser=$USER             #local host user name 本地主机用户名
private_key="~/.ssh/id_rsa" #private key for $localUser 本地用户的私钥路径
#tip : 先上传公钥到proxy主机 ssh-copy-id <user>@<proxy-host> -p <port>

#ssh options ssh选项（主要用以保持连接）
options='-o TCPKeepAlive=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=10 -o ControlMaster=auto -o ControlPath=~/.ssh/%r@%h:%p -o ControlPersist=yes -o StrictHostKeyChecking=no'

#---this host info saved at remote hosts 本机的相关信息 将记录到远程主机上
#When you have many hosts using this script for forwarding, it is better to design a unique name for this file on each host, which can describe the local information and distinguish it from other hosts. 当你有许多主机使用该脚本进行转发，最好为每一个主机上该文件设计一个独特的名字，能够描述本机信息，以及和其他主机区分

#important! ssh proxy info file, if it was empty, fallback value is $HOSTNAME-$remotePort  重要 记录本次ssh转发信息的文件名字，如果为空，将使用备用值$HOSTNAME-$remotePort
ssh_proxy_info_file="$HOSTNAME" #eg. home-nas

#ssh proxy info file path on the remote host, default is ~/proxy-hosts 远程主机上存放ssh转发信息文件的目录路径，默认是~/proxy-hosts
info_file_dir_on_remoteHost=proxy-hosts

#comments text will add to $/tmp/ssh_proxy_info_file, allow empty, default is $(uname -a) 本机注释信息将添加到$/tmp/ssh_proxy_info_file中，可以为空，默认为$HOSTNAME: $(uname -a)
localhost_comment="$HOSTNAME: $(uname -a)" #eg. this is a nas server at home  例如: 家里的NAS

action=${1:proxy} #

restart_ssh_proxy_at_hour=2 #Restart sshproxy at the same time every xx clock ,eg. 2:00

cron_interval_min=10 #cron task interval

#~~~~~~~~~~~~~~~~~~~~~~~~~~
#===action ｜ install
function exec_action() {
    #action--install ,first time 安装操作，第一次运行
    if [[ $action == 'install' ]]; then
        #ssh key auth localhost --> remote host  ssh密钥认证 本机-->远程主机
        echo "Check ssh key auth!"
        echo "input remote host password for $remoteUser 输入远程主机上$remoteUser的密码："
        ssh-copy-id -p $remotePort $remoteUser@$remoteHost

        #add a cron task 添加一个cron任务
        echo "+++++++++++++"
        echo "Add sshproxy as a crond task? 添加sshproxy为crond任务？[y/n]"
        echo "[y]:"
        read as_a_cron_task

        case $as_a_cron_task in
        y | YES | yes)
            if [[ -f /var/spool/cron/$USER ]]; then
                sed -i "/$script_path/d" /var/spool/cron/$USER
                crontab -l >/tmp/sshproxy_cron
                echo "@reboot $script_path
                */$cron_interval_min * * * * $script_path" >>/tmp/sshproxy_cron
                crontab /tmp/sshproxy_cron
            else
                echo "*/$cron_interval_min * * * * $script_path" >/tmp/sshproxy_cron
                crontab /tmp/sshproxy_cron
            fi
            crontab -l
            ;;
        *)
            echo
            ;;
        esac
    fi
}

#===check params
function check_ssh_params() {
    #check local port
    [[ -z $localPort ]] && echo "[ERR]: localPort can not be empty!" >>$log && exit 1

    #check remote sshd port 检查远程主机sshd端口
    [[ -z $remotePort ]] && echo "[ERR]: remotePort can not be empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remoteHost ]] && echo "[ERR]: remoteHost can not be empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remoteUser ]] && echo "[ERR]: remoteUser can not be empty!" >>$log && exit 1

    #check ssh private key file 检查密钥文件
    [[ -f $private_key ]] && echo "[ERR]: Can not find ssh private key file : $private_key !" >>$log && exit 1

    #check ssh proxy info file
    if [[ -z "$/tmp/ssh_proxy_info_file" ]]; then
        /tmp/ssh_proxy_info_file=${HOSTNAME}-$remotePort
        echo "[WARN]: param /tmp/ssh_proxy_info_file is empty! Fallback: ==> $/tmp/ssh_proxy_info_file " >>$log
    fi

    if [[ -z "$localhost_comment" ]]; then
        localhost_comment="$HOSTNAME-$(uname -a)"
    fi
}

#===proxy log 日志
function check_log_file() {
    local log_file_parent_dir=$(dirname $log)
    [[ -d $log_file_parent_dir ]] || mkdir -p $log_file_parent_dir
    [[ -f $log ]] || touch $log

    #log file size control 日志文件大小控制 10000Bytes
    if [[ $(stat -c %s $log) -gt $log_maxsize ]]; then
        local tmp_log=$(mktemp)
        tail -n 100 $log >$tmp_log #keep 100 lines log
        cat $tmp_log >$log
    fi
    echo "======LOG @ $(date)======" >>$log
}

#======checking 转发前检查
function check_ssh_forwarding() {
    #check ssh process 查找进程中是否已经存在指定的ssh转发进程
    local forwarding_process_info=$(ps -aux | grep $proxyPort:$localHost:$localPort | grep -v grep)

    #If the process already exists 如果转发进程已经存在
    if [[ -n $forwarding_process_info ]]; then
        #check state of remote host forwarding port 检查远程主机上转发端口状态
        # if [[ $(timeout 5 ssh -p $remotePort $remoteUser@$remoteHost "ss -tlpn |grep :$proxyPort") ]]; then
        #     #proxy服务器上ssh进程状态正常 退出
        # echo "Good! sshproxy is running." >>$log
        # exit 0
        # else
        #get ssh forwarding process PID 获取转发进程到PID
        #proxy服务器上ssh进程未检查到 或者链接到proxy服务器超时 终止本地到转发进程
        # kill -9 $forwarding_pid
        # fi
        #半夜两点断开进程重新连接
        if [[ $(date +%H) -eq 2 ]]; then
            local forwarding_pid=$(echo $forwarding_process_info | awk '{print $2}')
            kill -9 $forwarding_pid
            echo "restart ssh proxy"
        else
            echo "Good! sshproxy is running." >>$log
            exit 0
        fi
    fi
}

#=====Remote Port Forward======远程主机转发
function ssh_remote_forwarding() {
    # #check remote host sshd port 检查远程主机sshd端口 nc获取端口信息 返回值中含有ssh字样
    # if [[ ! $(timeout 5 nc $remoteHost $remoteHost | grep -i ssh) ]]; then
    #     echo "Can not connect sshd port $remotePort on $remoteHost, or $remoteHost:$remotePort is not a sshd port." >>$log
    #     kill -9 $forwarding_pid
    #     exit 1
    # fi

    echo "---start ssh proxy---" >>$log
    local errlog=$(mktemp)
    ssh -gfCNTR $proxyPort:$localHost:$localPort $remoteUser@$remoteHost -i $private_key -p $remotePort $options 1>>$log 2>$errlog

    ##ssh参数说明
    #-g 允许远程主机连接转发端口
    #-f 后台执行
    #-C 压缩数据
    #-N 不要执行远程命令
    #-R 远程转发
    local proxyPID=$(ps -ef | grep $proxyPort:$localHost:$localPort | grep -v grep | awk '{print $2}')

    #if there are some ERR infos in the errlog file ,save the err， kill the process and exit
    #如果错误日志中有内容（转发出错） 记录错误信息，杀死该进程并退出
    [[ -s $errlog ]] && cat $errlog >>$log && pkill -9 $proxyPID && exit 1

    #saved proxy info and copy to the remote host
    ssh -p $remotePort $remoteUser@$remoteHost "mkdir -p $info_file_dir_on_remoteHost"

    echo "=== generate at $(date) ===
        +++++ target server info +++++
          About:$localhost_comment
        ---------------------
          os-info:$(uname -a)
          ssh-port:$localPort
          ssh-user:$localUser
          proxy-port:$proxyPort
        ++++++info end+++
        SSH Remote Forwarding:
          target-host <-- remote forwarding --> $remoteHost
          " >/tmp/$ssh_proxy_info_file

    scp -P $remotePort /tmp/$ssh_proxy_info_file $remoteUser@$remoteHost:~/$info_file_dir_on_remoteHost/ >/dev/null
}

#+++++++++
#1.
exec_action $action

#2.
check_log_file

#3.
check_ssh_params

#4.
check_ssh_forwarding

#5.
ssh_remote_forwarding
