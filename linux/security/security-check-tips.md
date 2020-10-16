# 账户安全

## 删除、锁定或禁止不必要登录的用户

查看 `/etc/passwd` 和 `/etc/shadow` 文件，根据情况删、锁定或禁止不必要登录的用户。

```shell
#删除用户
userdel -r <username>  #-r连带删除用户家目录

#禁止用户登录shell（例如运行nginx的用户nginx）
chsh <username> -s /sbin/nologin  #将其默认shell改为nologin
#chsh <username> -s /bin/bash

#锁定用户
passwd -l <username>
#解除锁定
passwd -u <username> 
```

## 限制用户使用su(sudo)

>  Linux PAM( Pluggable Authentication Modules ) 提供了一个框架，用于进行系统级的用户认证。

编辑`/etc/pam.d/su`，取消此行注释，将只允许wheel组的用户使用su切换到root。

```shell
auth required pam_wheel.so use_uid
```

`sudo`和`su -l`（`su -`）配置类似，只是第一步分别修改的是`/etc/pam.d/sudo`和`/etc/pam.d/su-l`。

## 设置用户密码策略

### 禁止使用旧密码

编辑`/etc/pam.d/common-`，取消此行注释

```shell
 auth      sufficient    pam_unix.so  likeauth  nullok

password  sufficient   pam_unix.so  md5  shadow  nullok  remember=5  use_authtok
```



### 密码过期时间和长度

`/etc/login.defs`可设置新建用户的密码策略。该文件中有关密码策略配置示例：

```shell
PASS_MAX_DAYS	99999  #密码有效时间（天） 99999为永久
PASS_MIN_DAYS	0  #修改密码的最小间隔时间（天）
PASS_WARN_AGE	7  #密码过期前多少天开始提示
PASS_MIN_LEN  6 #密码最小长度（对root无效）
```



不建议使用以下类似的简单密码：123456  Password  123@qwer

使用以下命令查看密码策略设置：

　　#cat /etc/login.defs|grep PASS

可根据需要修改配置文件/etc/login.defs

　　PASS_MAX_DAYS 90 #新建用户的密码最长使用天数

　　PASS_MIN_DAYS 0  #新建用户的密码最短使用天数

　　PASS_WARN_AGE 7  #新建用户的密码到期提前提醒天数

​    PASS_MIN_LEN  9  #最小密码长度9

1.3 设置口令过期时间

对于采用静态口令认证技术的设备，账户口令的生存期不长于90天。

  操作：修改/etc/login.defs 文件，添加内容：PASS_MAX_DAYS 90

1.4 登录连续认证失败锁定帐号

对于采用静态口令认证技术的设备，应配置当用户连续认证失败次数超过6次，锁定该用户使用的账号。

参考配置操作：

CentOS:  在etc/pam.d/system-auth中auth列中添加：

​         auth required pam_tally.so onerr=fail deny=6 unlock_time=300

参数说明：

Deny：失败次数。

Unlock_time：锁定帐户多少秒后解锁。



2 系统服务安全

2.1 linux服务简介

| **服务进程**    | **说明**                                                     | **建议**     |
| --------------- | ------------------------------------------------------------ | ------------ |
| network         | 网卡管理                                                     | 开机启动     |
| kudzu           | 系统启动时自动检测硬件                                       | 开机启动     |
| sshd            | 远程登录服务                                                 | 开机启动     |
| crond           | 计划任务程序                                                 | 开机启动     |
| syslog          | 日志服务                                                     | 开机启动     |
| rsyslog         | 日志服务                                                     | 开机启动     |
| haldaemon       | 硬件自动检测挂载的功能                                       | 开机启动     |
| iptables        | 包过滤工具（系统自带防火墙）                                 | 开机启动     |
| acpid           | 电源管理服务                                                 | 开机启动     |
| cpuspeed        | 动态调整CPU处理能力功能                                      | 开机启动     |
| irqbalance      | CPU性能优化                                                  | 开机启动     |
| microcode_ctl   | CPU编码功能                                                  | 开机启动     |
| readahead_early | 优化系统的启动速度                                           | 开机启动     |
| irqbalance      | 用于多个处理器环境下的系统中断请求进行负载平衡的守护程序     | 根据需要开启 |
| kdump           | 在系统崩溃、死锁或者死机的时候用来转储内存运行参数的一个工具和服务 | 根据需要开启 |
| netdump         | 网络转储（Netdump）的功能                                    | 根据需要开启 |
| named           | 用于架设dns服务                                              | 根据需要开启 |
| netconsole      | 用于将本地主机的日志信息打印到远程主机上,便于远程用户查看日志信息 | 根据需要开启 |
| messagebus      | 进程间通讯）服务。确切地说，它与 DBUS 交互，为两个或两个以上的应用程序提供一对一的通讯 | 根据需要开启 |
| anacron         | 计划任务程序，是对cron的补充                                 | 根据需要开启 |
| atd             | 计划任务程序，任务只执行一次                                 | 根据需要开启 |
| autofs          | 外部存储设备的自动加载                                       | 禁用         |
| avahi-daemon    | 局域网里发现基于 zeroconf 协议的设备和服务                   | 禁用         |
| avahi-dnsconfd  | 局域网里发现基于 zeroconf 协议的设备和服务                   | 禁用         |
| bluetooth       | 用于支持蓝牙设备和功能的正常运行                             | 禁用         |
| NetworkManager  | 自动切换网络连接的后台进程                                   | 禁用         |
| capi            | 用于支持ISDN 设备                                            | 禁用         |
| dund            | 用于支持蓝牙设备和功能的正常运行                             | 禁用         |
| firstboot       | 安装之后的第一次启动时执行启动脚本                           | 禁用         |
| gpm             | 为文本模式下的Linux部分程序提供鼠标支持                      | 禁用         |
| hidd            | 用于支持蓝牙设备和功能的正常运行                             | 禁用         |
| ip6tables       | 用于 IPv6 的软件防火墙                                       | 禁用         |
| irda            | 用于实现红外无线数据传输                                     | 禁用         |
| mcstrans        | 如果你使用 SELinux 就开启它                                  | 禁用         |
| mdmonitor       | 与RAID设备相关的守护程序                                     | 禁用         |
| mdmpd           | 与RAID设备相关的守护程序                                     | 禁用         |
| microcode_ctl   | 可以编码以及发送新的微代码到kernel以更新Intel IA32系列处理器 | 禁用         |





2.2 停用与业务无关的服务

Centos：chkconfig --list 查看所有服务的状态

​        chkconfig <服务名> on 设置服务开机自启动

​        chkconfig <服务名> off 设置服务开机不启动

Ubuntu：sysv-rc-conf  进行简易图形化配置



3 网络访问安全

# 白名单与黑名单

3.1 设置访问控制策略限制能够使用ssh管理本机的IP地址

修改ssh配置文件 /etc/ssh/sshd_config

如需要限制只让192.168.1.0/24网段登录root用户，可在配置文件中添加一行：

allowusers [root@192.168.1](mailto:root@192.168.1).*  

注：可将root更改为需要限制登录的用户名；

保存后重启ssh服务：#service sshd restart

3.2 禁止root用户远程登陆

　检查 /etc/ssh/sshd_config：

　查看是否有此条配置：PermitRootLogin  yes

  可将此条配置修改为PermitRootLogin no

　保存后重启ssh服务：#service sshd restart

3.3 修改帐户TMOUT值，设置自动注销时间

　检查方法：

　#cat /etc/profile 查看有无TMOUT的设置

　添加配置：TMOUT=600

  意思是无操作600秒后自动退出

3.4 启动IPTABLES并设置相关策略

使用命令iptables-save来查看当前iptables策略

系统已经预置了部分策略，即input仅允许ICMP端口、22端口、80端口。

如果需要添加其他端口请添加相应IPTABLES实例。

3.5 修改SSH监听端口

当前为22端口，可修改为其他端口，如2233、2345等

centos修改配置文件 /etc/ssh/sshd_config

插入一行：port 2233

重启sshd服务：#server sshd restart



4 日志

4.1 用户登录日志

设备应配置日志功能，对用户登录进行记录，记录内容包括用户登录使用的账号，登录是否成功，登录时间，以及远程登录时，用户使用的IP地址。

▏参考配置操作：

\# Vi /etc/login.defs，添加LASTLOG_ENAB   yes

Linux的/var/log/wtmp和/var/log/wtmps,文件中记录着所有登录过主机的用户，时间，来源等内容，这两个文件不具可读性，可用last命令来看。

4.2 用户操作日志

设备应配置日志功能，记录用户对设备的操作，包括但不限于以下内容：账号创建、删除和权限修改，口令修改，读取和修改设备配置，读取和修改业务用户的话费数据、身份数据、涉及通信隐私数据。需记录要包含用户账号，操作时间，操作内容以及操作结果。

▏参考配置操作：

通过设置日志文件可以对每个用户的每一条命令进行纪录，这一功能默认是不开放的，为了打开它，需要执行

1)SUSE: # /usr/sbin/accton    /var/account/pacct

2)CentOS/REDHAT: # /usr/sbin/accton  /var/account/pacct

执行读取命令：# lastcomm [user name]

4.3 系统安全日志

设备应配置日志功能，记录对与设备相关的安全事件。

▏参考配置操作：

修改配置文件vi/etc/syslog.conf，

配置类似语句：*.err;kern.debug;daemon.notice;/var/log/messages

定义为需要保存的设备相关安全事件。