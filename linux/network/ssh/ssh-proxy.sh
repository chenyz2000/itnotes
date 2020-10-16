#!/bin/bash
#ssh proxy ， remote port forwarding
#--log file
log=./proxy.log   #proxy log
log_maxsize=10000 #Bytes

#--remote host as a proxy server 远程主机作为代理服务器
remoteHost=''        #remote host addr
remotePort=22        #remote host sshd port 远程主机的sshd端口
remoteUser=proxyuser #user on remote host 远程主机上的用户
proxyPort=2001       #remote host forward port 远程主机的转发端口 #common users could only use ports above 1024 普通用户只能使用1024以上端口

#--local host (this host which excutes this script) 本地主机（执行这个脚本的主机）
localHost=localhost         #this host
localPort=22                #local host sshd port 地主机sshd端口
localUser=$USER             #local host user 本地主机用户名
private_key="~/.ssh/id_rsa" #private key for above user 本地用户（上面那个localUser用户）的私钥

#ssh options ssh选项（用以保持连接）
options='-o TCPKeepAlive=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=10 -o ControlMaster=auto -o ControlPath=~/.ssh/%r@%h:%p -o ControlPersist=yes -o StrictHostKeyChecking=no'

#---this host info saved at remote hosts 本机的相关信息 将记录到远程主机上
#When you have many hosts using this script for forwarding, it is better to design a unique name for this file on each host, which can describe the local information and distinguish it from other hosts. 当你有许多主机使用该脚本进行转发，最好为每一个主机上该文件设计一个独特的名字，能够描述本机信息，以及和其他主机区分
ssh_proxy_info_file=''                  #important! ssh proxy info file 重要 记录本次ssh转发信息的文件 要能够体现本机的
info_file_dir_on_remoteHost=proxy-hosts #ssh proxy info file path on the remote host 远程主机上存放ssh转发信息文件的目录路径
localhost_comment=""                    #comments text will add to $ssh_proxy_info_file 本机注释信息 将添加到 $ssh_proxy_info_file中

#ssh key auth
action=$1 #
# had_authed=n #do not edit it | 是否已进行上传ssh公钥

#===check params
function check_ssh_params() {
    #check local port
    [[ -z $localPort ]] && echo "localPort is empty!" >>$log && exit 1

    #check remote sshd port 检查远程主机sshd端口
    [[ -z $remotePort ]] && echo "remotePort is empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remoteHost ]] && echo "remoteHost is empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remoteUser ]] && echo "remoteUser is empty!" >>$log && exit 1

    #check ssh private key file 检查密钥文件
    [[ -f $private_key ]] && echo "Can not find ssh key file : $private_key !" >>$log && exit 1

    #check ssh proxy info file
    [[ -z $ssh_proxy_info_file ]] && echo "params ssh_proxy_info_file is empty!" | tee -a $log && exit 1
}

#===ssh key auth localhost --> remote host  ssh密钥认证 本机-->远程主机
function ssh_key_auth() {
    if [[ $action == 'auth' ]]; then
        echo "excute:  ssh-copy-id -p $remotePort $remoteUser@$remoteHost"
        echo "input remote host password for $remoteUser 输入远程主机上$remoteUser的密码："
        ssh-copy-id -p $remotePort $remoteUser@$remoteHost
        if [[ $? -eq 0 ]]; then
            sed -i "/had_authed=/c had_authed=y" $0
        fi
    fi
}

#===proxy log 日志
function check_log_size() {
    [[ -f $log ]] || touch $log
    #log file size control 日志文件大小控制 10000Bytes
    if [[ $(stat -c %s $log) -gt $log_maxsize ]]; then
        local tmp_log=$(mktemp)
        tail -n 20 $log >$tmp_log
        cat $tmp_log >$log
    fi
    echo "======start @ $(date)======" >>$log
}

#===cron task 周期任务
function check_cron_task() {
    #script is this script file path
    local script=$0
    [[ $(echo $script | grep $PWD) ]] || script=$PWD/$0
    chmod +x $script

    # add a cron task if it does not exist
    if [[ ! $(crontab -l | grep $script) ]]; then
        cronlist=$(mktemp)
        echo -e "1 * * * * $script\n@reboot $script" >>$cronlist
        crontab $cronlist
    fi
}

#======checking 转发前检查
function check_ssh_forwarding() {
    #check ssh process 查找进程中是否已经存在指定的ssh转发进程
    forwarding_process_info=$(ps -ef | grep $proxyPort:$localHost:$localPort | grep -v grep)

    [[ -n $forwarding_process_info ]] && forwarding_pid=$(echo $forwarding_process_info | awk '{print $2}')

    #If the process already exists 如果转发进程已经存在
    if [[ -n $forwarding_process_info ]]; then
        #check remote host sshd port 检查远程主机sshd端口
        if [[ $(timeout 5 nc yixuxi.top 10022 | grep -i ssh) ]]; then
            echo "Can not connect $remoteHost sshd port $remotePort" >>$log
            kill -9 $forwarding_pid
            exit 1
        fi
        #check remote host forwarding port 检查远程主机上转发端口
        #todo 应该检查是不是ssh端口
        if [[ $(timeout 5 ssh -p $remotePort $remoteUser@$remoteHost "ss -tlpn |grep :$proxyPort") ]]; then
            echo "sshproxy is running" >>$log
            exit 1
        else
            kill -9 $forwarding_pid
        fi
    fi
}

#=====Remote Port Forward======远程主机转发
function ssh_remote_forwarding() {
    echo "---start ssh proxy" >>$log
    local errlog=$(mktemp)
    ssh -gfCNTR $proxyPort:$localHost:$localPort $remoteUser@$remoteHost -i $private_key -p $remotePort $options 1>>$log 2>$errlog

    ##ssh参数说明
    #-g 允许远程主机连接转发端口
    #-f 后台执行
    #-C 压缩数据
    #-N 不要执行远程命令
    #-R 远程转发
    local proxyPID=$(ps -ef | grep $proxyPort:$localHost:$localPort | grep -v grep | awk '{print $2}')

    #if there is some err info in the errlog file ,save the err， kill the process and exit
    #如果错误日志中有内容（转发出错） 记录错误信息，杀死该进程并退出
    [[ -s $errlog ]] && cat $errlog >>$log && pkill -9 $proxyPID && exit 1

    #saved proxy info and copy to the remote host
    ssh -p $remotePort $remoteUser@$remoteHost "mkdir -p $info_file_dir_on_remoteHost"
    echo "++++++++
$localhost_comment
++++++++
update-time:$(date)
ssh-port:$localPort
ssh-user:$localUser
proxy-port:$proxyPort
remote-port:$remotePort
target-host <-- remote forwarding --> $remoteHost
" >$ssh_proxy_info_file

    scp -P $remotePort $ssh_proxy_info_file $remoteUser@$remoteHost:~/$info_file_dir_on_remoteHost/ >/dev/null
}

#+++++++++
#1.
check_ssh_params
#2.
ssh_key_auth
#3.
check_log_size
#4.
check_cron_task
#5.
check_ssh_forwarding
#6.
ssh_remote_forwarding
