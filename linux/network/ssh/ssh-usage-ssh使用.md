[TOC]

下文中，客户端即是用户使用的主机，目标主机或者远程主机位sshd服务器。

# 配置文件

- 服务端：一般是`/etc/ssh/sshd_config`

  `-f`选项可指定配置文件

- 客户端：一般是`/etc/ssh/ssh_config`（全局）或`$HOME/.ssh/config`（用户）

  `-F`选项可指定配置文件

# 远程登录

```bash
ssh [-p port] user@host
ssh -p 2333 root@host
ssh -l user root@host
ssh host
```
- port：要登录的远程主机的端口，如果省略则默认为22（以下示例中如无指定均表示使用22）。

- user：要登录的主机上的用户名，也可使用`-l`指定（此时无需`@`连接用户名和服务器地址），如果省略用户名（和`@`），将会以当前用户名尝试登录ssh服务器，例如root用户执行`ssh host`同于`ssh root@host`。
- host：要登录的主机地址。

## 密钥登录

使用非对称加密的密钥，可免密码登录。

1. 生成密钥——生成非对称加密的密钥对

   ```shell
   ssh-keygen   #根据提示选择或填写相关信息
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" #相等于执行ssh-keygen后一直回车(均默认)
   ```
   - t：加密类型，有dsa、ecdsa 、ed25519、rsa等
   - b：密钥长度
   - f：密钥放置位置
   - N：为密钥设置密码

2. 上传密钥——将密钥对中的公钥上传到ssh服务器

   ```shell
   ssh-copy-id user@host
   ssh-copy-id -i ~/.ssh/test.pub user@host  #有多个公钥时可使用参数-i指定一个公钥
   ```

   提示：上传时需要输入密码。

   公钥内容将添加到登录用户在服务器的`~/.ssh/authorized_keys`文件中。

   确保`authorized_keys`文件的权限为600，`.ssh`文件夹权限为700。


## 别名登录

为需要经常登录的服务器设置别名，简化登录步骤。

在`~/.ssh/config`（如无该文件则创建之）中配置：

```
Host host1 #host1为所命名的别名
hostname xxx.xxx.xxx.xxx #登录地址
user user1  #用户名
#port 1998  #如果修改过默认端口则指定之
#IdentityFile  ~/path/to/id_rsa.pub #如果要指定公钥
#IdentitiesOnly yes #只使用指定的公钥进行认证
```

登录时直接使用`ssh host1`即可。

## 跳板登录

在某些网络限制的情况下，需要通过跳板机（可能不止一个跳板机）登录到目标服务器：

**客户端** ---> **跳板机** ---> **目标主机**

通常地，先从客户端登录到跳板主机，再从跳板主机登录到目标主机：

```shell
ssh user@jump-host   #从客户端登录到跳板机
ssh user@target-host #从跳板机登录到最终目标主机
```



使用以下方式可以直接从客户端主机登录到跳板机：

- 使用`-t`分配伪终端，相当于合并多次ssh命令：

  ```shell
  ssh -t user@jump-host ssh -t user@target-host
  ```

- 使用代理跳跃登录（`-J`参数或`ProxyJump`配置）

  原理是在跳板机上建立TCP转发，让客户端ssh数据直接转发到目标服务器上等ssh端口。

  ```shell
  #注意，跳板机的端口需要直接在地址后面添加 以冒号分隔
  ssh -J user@jum[:port] user@target -p <port>

  #如有多个跳板机使用逗号隔开 #客户端->jump1服务器->jump2服务器->target服务器
  ssh -J user@jump1,user@jump2:2333 user@target -p 22

  #通过server1跳跃到server2 使用X转发打开server上的firefox
  ssh -J user@server1 user@server2 -X firefox
  ```

  `-J`是`ProxyJump`的快捷使用方式。使用`ProxyJump`实现Jump直接跳跃登录功能：

  ```shell
  ssh user@target -o ProxyCommand='ssh user@jump-host -W %h:%p'
  ```

  或者在`~/.ssh/config`中进行配置如下内容，然后使用`ssh target`直接登录到target：

  ```shell
  Host jump #跳板机配置
      HostName 10.10.1.1
      Port 2333
      User user1

  Host target #目标主机配置
      HostName 10.10.10.10
      Port 1010
      User user
      ForwardAgent yes
      ProxyCommand ssh jump -q -W %h:%p
  ```

## 转发认证

为了方便，一般我们会配置，客户端到跳板机的密钥认证，以及跳板机到目标主机的密钥认证（甚至使用同一套密钥）：

> 客户端---ssh-keys--->跳板机
>
> 跳板机---ssh-keys--->目标主机

但在某些对安全性有较高要求的情况下，我们**不希望跳板机可以通过密钥认证登录到目标主机**（可能没有配置跳板机到目标主机的密钥认证，甚至为了安全关闭了目标主机的密码登录），而是**将客户端的公钥直接存放到目标服务器**。

> 客户端：私钥<======>公钥：目标服务器

为了实现使用客户端使用密钥登录的目标服务，可以使用转发密钥认证的方式实现。

不过，如果**使用`J`跳跃登录无需使用认证转发功能**即可实现上诉密钥登录要求，跳板机仅作为一个流量转发者。

实现认证转发的方法：

- 配置`ForwardAgent yes`

  在客户端的`/etc/ssh/ssh_config`或`~/.ssh/config`中配置`ForwardAgent yes`即可。

- `-A` 参数

  如未配置`ForwardAgent yes`，也可以使用`-A`参数，其作用是：

  > 允许转发认证代理的连接

  逐步跳跃登录的方式：

  ```shell
  #1. 从客户端登录到跳板机 并将密钥交给agent 以供跳板机使用
  ssh -A user@jump-host
  #2. 从跳板机登录到目标主机将使用来自客户端的密钥
  ssh user@target-host
  ```

  分配伪终端`-t`登录的方式：

  ```shell
  ssh -t -A user@jump-host ssh -t user@target-host
  ```

## 连接复用

在已经连接到某个服务器的情况下，再连接该服务器时将直接从先前的连接缓存中读取信息，加快连接速度，尤其是于网络不太稳定的场景下。

在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

```shell
ControlMaster auto
ControlPath ~/.ssh/socket/%r@%h:%p #连接信息存储路径
ControlPersist yes  #连接保持
ControlPersist 1h  #连接保持时间
```

## 远程命令

直接在登录命令后添加命令，可使该命令在远程主机上执行，示例：

```shell
ssh [-p port] user@host <command>
ssh root@192.168.1.1 whoami

#将本地.vimrc内容传入远程主机的.vimrc中
ssh root@192.168.1.1 'cat > .vimrc' < .vimrc

#多条命令使用引号包裹起来
ssh root@192.168.1.1 'echo `whoami` > name && mv -f name myname'
```

如果执行某个命令遇到`command not found`，而实际上远程主机上可以正常执行该命令，尝试使用该命令在远程主机上的绝对路径，具体参看[问题解决](#问题解决)中“远程命令cmmand not found”。

远程命令执行完毕后，即会退出ssh连接。

使用`-t`参数分配伪终端，且远程命令的最后一条命令为`bash`（或其他shell），则可以在远程主机执行命令后仍停留在远程主机的shell中。

示例登录后自动进入某个目录：

```shell
ssh -t <host> 'cd /tmp;bash'
```

如果是交互式操作，例如使用vim操作远程主机的文件，配合scp使用，示例：

```shell
vim scp://user@host[:port]//path/to/file
```

# X转发

转发远程主机上应用程序的X11图形界面到本机。X转发的要求：

- 服务端
  - xorg-server，xorg-xauth，启动X服务。

  - 确保`sshd_config`关于X的配置如下：

    ```shell
    X11Forwarding yes
    X11DisplayOffset 10
    X11UseLocalhost no
    ```
- 客户端

  - 有X 环境（windows需要安装x实现如Xming等）

```shell
#打开远程主机的firefox （或者登录到远程主机上再执行命令）
ssh -X user@host firefox  #或配置ForwardX11 yes 则可不写出-X
#或
ssh -Y user@host firefox  #或者ForwardX11Trusted yes 则可不写出Y
```

- `-X`  远程机器将被视为不受信任的客户端，本地客户端向远程机器发送命令并接收图形输出，如果某些命令违反了某些安全设置，将收到错误提示。 可在客户端ssh配置中添加
- `-Y`  远程机器将被视为受信任的客户端。 （其他图形(X11)客户端可以从远程机器中嗅探数据（制作屏幕截图、做键盘记录和其他讨厌的东西，甚至可以更改这些数据。）

# 端口转发

> 隧道是一种把一种网络协议封装进另外一种网络协议进行传输的技术。

- 使用1024以下的端口需要root权限。

- 端口转发命令配合`-g`参数，允许远程主机(remote hosts)连接到本地转发的端口(local forward port)，如果不使用该参数则只允许本地主机建立连接。

  也可在代理主机的配置文件`/etc/ssh/sshd_config`中设置：`GatewayPorts yes`，以允许远程主机向本地转发端口建立连接。

- 禁止端口转发：在配置文件`/etc/ssh/sshd_config`中设置`AllowTcpForwarding no`。

- 可配合[保持连接](#保持连接)的autossh，创建systemd units持续提供转发服务。

- 动态转发与本地/远程转发

  **动态转发是正向代理，本地/远程转发是反向代理。**

  **”正向(代理)“ 代理客户端**：正向代理代表客户端向服务器发送请求，使真实客户端对服务器不可见。

  **”反向(代理)“ 代理服务端**：反向代理代表服务器为客户端提供服务，使真实服务器对客户端不可见。

  (第2个代理是动词)

## 动态端口转发（socks代理）

动态转发本机指定端口的数据到远程主机。

在本机分配一个 socket 侦听端口，一旦这个端口上有了连接，该连接就经过ssh隧道转发到远程主机，通过远程主机与目标连接。

```shell
客户端C----->代理主机P----->多个目标主机的多个端口
```

应用场景举例：代理主机科学上网。

```shell
ssh -D  [bind_address:]<local-port> <proxy-user>@<proxy-host> [-p proxy-port]
```

- bind_address：指定绑定的地址，如该值为空即绑定到`127.0.0.1`，可使用`0.0.0.0`或`*`绑定到任意主机（下同，不在赘述）。

- local-port：绑定的端口。


示例，本机通过远程主机hostP代理访问不存在的网站`google.com`：

```shell
ssh -fCNTD *:2333 user@hostP
```

*参看[参数说明](#常用参数)了解各个参数意思。*

在本机系统设置中全局（或者浏览器应用设置中）添加socks代理，地址：`127.0.0.1`，端口`2333`，本机即可通过服务器hostP代理访问；打开浏览器访问`google.com`将通过hostP代理`google.com`。

提示：客户端配置socks5代理后使用（或设置全局的代理，可配合PAC使用）。

## 本地端口转发

将本地主机的某个端口转发到远端指定机器的指定端口。
在本地主机上分配了一个 socket 侦听端口， 一旦这个端口上有了连接， 该连接就经过ssh隧道转发到程主机的端口上。

```shell
客户端C----->本地主机L----->远程主机R
```

本地转发中：

- 本地主机L：既是执行转发命令的主机，也是作为流量转发的中间代理主机。
- 远程主机R：最终提供服务的目标主机。

```shell
ssh -L [bind_address:]<local-port>:<target-host>:<target-port> [user>@]<local-host>
```



应用场景举例：网络安全管控。有主机A、B，主机B运行的web服务监听于80端口，处于某些考虑，禁止用户直接访问B的80端口，在A执行了本地转发，将A的80端口绑定到B的80端口，这样用户访问A的80端口即可访问B的80的web服务。

示例，转发本机8080端口到`www.kernel.org`：

```shell
#转发该主机的8080端口到kernel.org的80端口   访问该主机的8080端口的流量即被转向www.kernel.org
ssh -fNCL *:8080:www.kernel.org:80 user@localhost
```

假如本地主机的IP是`192.168.0.1`，访问`192.168.0.1:8080`即访问`www.kernel.org`。

## 远程端口转发（反向隧道连接）

将远程主机的某个端口转发到本地端指定机器的指定端口。

本地主机主动向远程主机发起连接，建立反向隧道。远程主机上分配了一个 socket 侦听端口，一旦这个端口上有了连接，该连接就经过ssh隧道转发到本地主的端口。

```shell
C客户端----->远程主机R----->本地主机L
```

远程转发中：

- 本地主机L：既是执行转发命令主机，也是最终提供服务的目标主机。
- 远程主机R：作为流量转发的中间代理主机。

```shell
ssh -R [bind_address:port:<local-host>:<local-port> [<remote-user>@]<remote-host>
```


应用场景举例：内网穿透。在内网服务器与公网服务只见建立反向隧道，转发公网服务器的2222端口到内网服务器的22端口，用户访问公网服务器的2222端口即访问内网服务器的22端口。

示例，转发远程主机的9500端口到本地主机的5900：

```shell
ssh -gfNCL *:9500:localhost:5900 user@remote
```

假如位于NAT后的本地主机运行了xvnc（监听于5900端口），远程主机remote为公网主机，经过以上转发后，使用vnc客户端访问`remote:9500`即可连接上本地主机的vnc服务。

# 保持连接

## alive存活保持

默认情况下，连接的会话在空闲一段时间后会自动登出。为了保持会话，在长时间没有数据传输时客户端可以向服务器发送一个激活信号；与之对应，服务器也可以在一段时间没有收到客户端消息时定期向客户端发送一个激活信号。

另外可开启`TCPKeepAlive`以发送TCP连接消息，其可检测到连接异常，以避免僵尸进程产生。

可根据情况在服务端或客户端设置：

- 服务端`/etc/ssh/sshd_config`中添加

  ```shell
  TCPKeepAlive yes  #可选 保持tcp连接
  ClientAliveInterval 60 #如果设置为0 则表示不发送激活信息。
  ClientAliveCountMax 5
  ```

  服务端每60s向连接的客户端传送信息，客户端连续5次无响应则自动关闭该连接。

- 客户端`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加

  ```shell
  TCPKeepAlive yes  #可选 保持tcp连接
  ServerAliveInterval 60
  ServerAliveCountMax 5
  ```

  每60s向连接的服务端端传送信息，服务端连续5次无响应则自动关闭该连接。

也可以在ssh命令中使用`-o`参数指定向服务端发送激活信息间隔时间：

```shell
ssh -o ServerAliveInterval=60 user@host
```

## autossh工具

autossh可以在监测ssh连接状态，当ssh断开后会自动重新发起连接。

在ssh命令前使用`autossh -M <port>`即可，其指定一个端口，用以持续监听当前ssh连接状态。

```shell
autossh -M 2333 ssh -fCNR 8080:localhost:80 user@remote-host
```

一个autossh的systemd units文件示例，可放置于`/etc/systemd/system/autossh.service`或`$HOME/.config/systemd/user/`下。

```shell
[Unit]
Description=Keeps a tunnel to 'example.com' open
After=network.target

[Service]
User=autossh
ExecStart=/usr/bin/autossh -M 5678 -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -NR 1234:localhost:22 -i /home/autossh/.ssh/id_rsa someone@remote-host
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

# 文件传输

## scp远程复制

scp是基于ssh的远程复制，使用**类似cp命令**。基本形式：

```shell
scp </path/to/local-file> user@host:</path/to/file>  #本地到远程
scp user@host:</path/to/file> </path/to/local-file>  #远程到本地
```

注意：scp遇到软连接时，**会复制软连接的源文件**！可以打包要复制的文件，待scp复制到目标主机后再解包，或者换用其他工具如rsync。

常用选项：

- -P  指定远程主机的端口号
- -C  使用压缩
- -r  递归方式复制（即复制文件夹下所有内容）
- -p  保留文件的权限、修改时间、最后访问时间
- -q  静默模式（不显示复制进度）
- -F  指定配置文件

示例——复制本地ssh公钥到远程主机：

```shell
#复制本地公钥到远程主机 并将其命名为authorized_keys
scp ~/.ssh/id_rsa.pub root@ip:/root/.ssh/authorized_keys
#指定端口需要紧跟在scp之后
scp -P 999 ~/.ssh/id_rsa.pub root@ip:/root.ssh/authorized_keys
```

## sftp传输协议

使用sftp协议可以同ssh服务器进行文件传输，访问地址类似：

> sftp://192.168.1.100:22/home/<user>/path/to/file

## sshfs文件系统

> SSHFS 是一个通过 SSH 挂载基于 FUSE 的文件系统的客户端程序。

需要安装有`sshfs`。

```shell
#sshfs [user@]host:[dir] <mountpoint> [options] #挂载
sshfs ueser1@host1:/share /share -C -p 2333 -o allow_other

#fusermount -u <mount-point>  #卸载
fusermount -u /share
```

常用选项有：

- `-C` 启用压缩

- `-p` 指定端口

- `-o allow_other` 允许非root用户读写


`/etc/fastab`自动挂载示例：

```shell
user@host:/remote/folder /mount/point  fuse.sshfs noauto,x-systemd.automount,_netdev,users,idmap=user,IdentityFile=/home/user/.ssh/id_rsa,allow_other,reconnect 0 0
```

# 安全策略

- 如果服务端openssh版本过低，应该更新openssh，尤其是某些版本已经曝出过重大漏洞的情况。

- 检查服务端sshd使用的加密算法，应该去掉已经被证实的弱加密算法，例如`arcfour`和`des`系列算法。

  新版本openssh一般会不采用已经曝光的弱加密算法。

  可以用nmap扫描目标ssh服务器，获取其sshd使用的加密算法（encryption_algorithms）

  ```shell
  nmap --scrip "ssh2*" <server>
  ```

  可以在`sshd_config`中配置`Ciphers`指定使用高强度加密算法，例如：

  ```shell
  Ciphers aes256-ctr chacha20-poly1305@openssh.com aes256-gcm@openssh.com
  ```

  修改后需要重启sshd服务。

- 登录记录查看

  - 登录历史
    - 用户最近登录情况：`lastlog`
    - 登录成功的记录：`last`
    - 登录失败的记录：`lastb`
  - 当前登录用户
    - 当前已登录用户列表（以及登录的用户正在执行什么操作）：`w`
    - 当前已登录的用户信息：`who`

- 防御工具

  - [fail2ban](https://github.com/fail2ban/fail2ban)
  - [sshguard](https://www.sshguard.net/)

- root用户登录限制

  禁止root用户登录或仅允许其使用密钥登录。

  修改服务器的`/etc/ssh/sshd_config`文件中的`PermitRootLogin` 的值，值可以为：

  - `no`或`yes`  禁止或允许root用户登录
  - `prohibit-password`或者`without-password`  不允许使用密码登录（可以使用其他认证方式，例如ssh密钥）
  - `forced-commands-only`  只能使用密钥登录 且 仅允许使用授权的命令

- 禁止某些用户使用shell（以禁止其登录）

  某些用户可能只用于自动启动某个守护进程，无需登录，可以修改其shell为nologin，修改方法：

  - `chsh -s /sbin/nologin username`  username为用户的名字
  - 编辑`/etc/passwd`文件，找到该用户所在行，将`/bin/bash`字样改为`/sbin/nologin`。


- 更改默认的22端口


减少被工具批量扫描的几率。修改服务器的`/etc/ssh/sshd_config`文件中的`Port` 值为其他可用端口。

如果要监听多端口，则添加多行`Port`，如果要指定监听的地址，添加`ListenAddress`行：

  ```shell
  Port 1234
  Port 520
  ListenAddress 192.168.0.1
  ListenAddress 0.0.0.0
  ```

- 使用密钥而非密码登录

  安全但不方便。

  ```shell
  ssh-keygen  #或者ssh-keygen -t rsa 4096 客户机生成密钥
  ssh-copy-id -p 23579 user@host  #上传公钥到服务器
  ```

  注意，dsa密钥已经证实为不安全，rsa密钥位数过低也较为不安全，推荐至少4096位。


- IP白名单和黑名单

  - 黑名单`/etc/hosts.deny`中添加禁止列表。
  - 白名单`/etc/hosts.allow`中添加允许列表。

- 用户白名单和黑名单

  - sshd控制，在`/etc/sshd_config`中添加配置行

    - 白名单
      - 用户：`AllowUsers username1 username2`
      - 用户组：`AllowGroups groupname1 groupname2`
    - 黑名单
      - 用户：`DenyUsers username1 username2`
      - 用户组：`DenyGroups groupname1 groupname2`

  - PAM控制

    1. 在`/etc/pam.d/sshd`文件中添加：

       ```shell
       auth  required  pam_listfile.so  item=user  sense=deny  file=/etc/ssh/deny onerr=succeed
       ```

       `sense`取值：黑名单值为`deny`，白名单值为`allow`。

    2. 在`/etc/ssh/denyhosts`中添加黑名单/白名单用户，一行一个用户名。

----

# 常用参数

- `p`：指定要连接的远程主机的端口
- `f`：成功连接ssh后将指令放入后台执行
- `C`：压缩所有数据
- `N`：不执行远程命令（不登录到服务器执行命令）
- `D`：动态端口转发
- `R`：远程端口转发
- `L`：本地端口转发
- `g`：（配合端口转发）允许远程主机连接到建立的转发的端口（不使用该参数则只允许本地主机建立连接）
- `t`：分配伪终端（可以用来执行任意的远程计算机上**基于屏幕的程序**）
- `T`：不分配TTY
- `A`：开启身份认证代理转发
- `q`：安静模式（不输出错误/警告）
- `v`：显示详细信息（可用于排错）

# 问题解决

ssh命令中使用参数`-v`可输出详细的调试信息

`-vvv`可以显示更多的信息。



## 密钥问题

- 非root用户应上传公钥仍不能使用密钥登录（提示输入密码）：可能是selinux出于enforcing模式。

- > error fetching identities for protocol 1: agent refused operation

  ```shell
  eval "$(ssh-agent -s)"
  ssh-add
  ```

- 已经进行ssh密钥认证而提示输入密码

  - 确保用户家目录权限至少700

  - 确保`.ssh`文件夹权限为700，`authorized_keys`及公私钥文件的权限为`600`

    ```shell
    chmod 600 ~/.ssh/* && chmod 700 ~/.ssh
    ```

  - 客户端存在多个密钥对时，可能需要指定使用的私钥

    使用`-i`指定**私钥** ：

    ```shell
    ssh -i /path/to/private-key/ [-p port] user@host
    ```

## 登录卡慢但是能够登录成功

这里的卡或慢不包括因为网络因素问题（比如与远程主机之间的网络很差、远程主机防火墙监测时间过长）

- 服务端polkit或systemd-logind问题

  依次使用systemctl status查看sshd、systemd-logind和polkit状态，如果法有有错误信息（一般为红色），重启有问题的服务。

  如果问题仍然存在，重装polkit、openssh-server等软件包，重启服务和整个系统。

- 服务端设置了GSS认证（GSSAPIAuthentication，公共安全事务认证）

  - `GSSAPIAuthentication` 是否允许使用基于 GSSAPI 的用户认证，默认值为"no"。
  - `GSSAPICleanupCredentials` 是否在用户退出登录后自动销毁用户凭证缓存，默认值为"yes"。

  若服务器开启了该验证机制，但客户端并未使用该身份验证机制，则会导致验证过程出现延迟。

  释掉服务端`/etc/ssh/sshd_config`中的`GSSAPI`相关行，或者设置相关行值为`no`，重启sshd服务。

- 服务端设置了DNS查询

  服务器根据客户端IP进行DNS查询，但DNS因为（各种网络因素）查询时间过长或者查询失败。`/etc/ssh/sshd_config`中的`UseDNS`设置为`no`，重启sshd服务。

## 各种登录失败问题

- 目标服务器上无该帐号，常见原因是目标服务器使用某些用户信息同步工具（如nis），但是目标服务器的相关服务（如nis的ypbind服务未启动），因而找不到该帐号。

- `System is booting up. See pam_nologin(8)`

  删除服务端的`/var/run/nologin`或`/etc/nologin`或`/var/nologin`或`/run/nologin`等文件。

- ` REMOTE HOST IDENTIFICATION HAS CHANGED` 远程主机公钥未能通过主机密钥检查

  客户端首次登录ssh服务器时，客户端会记录服务器的公钥信息到`~/.ssh/known_hosts`（已知主机列表）文件中，每个主机一行。

  如果连接服务器时，服务器公钥与know_hosts列表中记录的公钥不同（例如远程主机更改了密钥），就会校验不通过。

  解决方案：
  - 删除客户端`.ssh/known_hosts`文件中检查不通过的ssh服务器的公钥信息
  - 关闭客户端的严格主机密钥检查(strict host key check)

  在`.ssh/config`（或`/etc/ssh/ssh_config`）中添加

  ```shell
  StrictHostKeyChecking no
  ```

  如果无需严格的主机密钥检查，也可以将已知主机信息文件指向`/dev/null`。

- `command not found` 执行远程命令提示找不到命令

  使用ssh服务器上的**非root用户**执行位于其`/sbin`（或`/usr/sbin/`）目录下的程序时，提示"command not found"，解决方法：

  - 使用root用户执行

  - 如果该用户具有sudo权限，在命令前添加sudo执行

  - 使用绝对路径执行，例如：

    ```shell
    /usr/sbin/ip a
    /usr/sbin/lspci
    ```

- `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`

  检查服务端`/etc/ssh/sshd_config`是否关闭了密码登录。如需开启密码登录，修改该行：

  ```
  PasswordAuthentication no #注释该行或值改为yes 再重启sshd服务
  ```

- 协议不支持问题

  均可以升级服务器/客户端的ssh程序版本解决。

  - `no matching key exchange method found. Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1`

    服务端ssh版本过低，不支持`diffie-hellman-group1-sha1`等协议，在其`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

    ```shell
    KexAlgorithms +diffie-hellman-group1-sha1
    ```

  - `no compatible cipher.The server supports these cipher:  aes128-ctr,aes192-ctr,aes256-ctr`

    服务端不支持`aes128`等加密协议。在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

    ```shell
    Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
    ```

