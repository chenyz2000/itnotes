# vnc简介

VNC 由AT&T 的剑桥研究实验室开发，可实现远程图像显示和控制。

VNC可是指一种通信协议——[Virtual Network Computing](https://en.wikipedia.org/wiki/Virtual_Network_Computing)，也代指实现这种协议的工具——Virtual Network Console（ 虚拟网络控制台）。

VNC工具分为服务端和客户端，服务端提供两种服务方式：

- 物理会话：直接控制物理显示器显示的内容，所有连接上的用户看到的是同一图像。
- 虚拟会话：同时运行多个虚拟会话，各个会话图像不同。

# 常见VNC实现

VNC作为一种通用协议，现有多种实现工具：

- [TigerVNC](https://www.tigervnc.org)

  TightVNC的分支，取代原TightVNC，虚拟会话使用`Xvnc`，物理会话使用`x0vncserver`。

  如今Linux发行版中最常用的VNC实现（一些发行版中安装vncserver包即是安装tigervnc）。tigervnc包含一个vnc客户端vncviewer。

- [TurboVNC](https://turbovnc.org/)

  TightVNC的分支，特点是对图形传输方面的优化。

- [RealVNC](http://www.realvnc.com)

  2002年剑桥研究室实验室关闭，后来VNC的创始人创立的RealVNC公司开发的产品，客户端可以通过该产品的服务器连接服务端，提供商用版本，以及有一定限制的免费版本。

- [vino](https://wiki.gnome.org/Projects/Vino)及[vinagre](https://wiki.gnome.org/Apps/Vinagre)

  [GNOME](https://www.gnome.org)项目的子项目，vino为服务端，vinagre为客户端（还支持SPICE、RDP、SSH等协议）

- x11vnc

  仅为实现X11的服务端。

# VNC服务端配置

以下以tightvnc系的tigervnc为主，tightvnc命令与之类似。

## 虚拟会话

- 启动会话

  最简单方法是执行`vncserver`，它是`Xvnc`的包装脚本（`Xvnc`命令使用通`x0vncserver`）。

  用户首次执行该命令，会提示创建适用于该用户vnc会话的密码。

  vnc服务会会一次为开启的虚拟会话编号，每个会话使用一个端口，编号默认从`:1`开始，对应端口为`5901`，以此类推。

  ```shell
  vncserver  #如果没有会话，一般从:1开始 端口5901
  vncserver :2  #指定会话为:2 端口5902
  ```

- 管理vnc会话

  - `vncserver -list`参数查看会话列表

  - `vncserver -kill <会话编号>`参数终止某个会话
  
    ```shell
    vncserver -kill :1  #终止1号会话
    ```
  
  - `vncpassword`修改密码

## 直接控制

TigerVNC使用`x0vncserver`，RealVNC有自己的实现，还可以使用`x11vnc`。

`x0vncserver`实现更为低效，较之更推荐`x11vnc`。

直接控制的VNC使用端口5900。

### x0vncserver

```shell
#-display指定使用的物理显示 并指定密码文件（可由vncpasswd生成）
x0vncserver -rfbauth ~/.vnc/passwd -display :0
x0vncserver -display :0 -passwordfile ~/.vnc/passwd  #作用同上
```

### x11vnc

启动服务：

```shell
x11vnc -display :0  #没有安全保证 将建立一个没有密码的VNC!!!
#设置一个密码 但是在服务端执行ps查看进程可看到密码
x11vnc -wait 50 -noxdamage -passwd PASSWORD -display :0 -forever -o /var/log/x11vnc.log -bg

x11vnc -gui  #可以启动一个tk编写的图形界面前端
```

直接运行将建立一个没有密码的VNC，`-passwd`虽然能设置密码，但仍能通过ps命令查询进程获取密码信息。

- 加密

  - ssh转发加密

    1. 使用`-localhost`参数启动服务，绑定vnc服务到localhost从而拒绝外部连接：

       ```shell
       x11vnc -localhost
       ```

    2. 客户端使用ssh转发，将服务端的5900端口到客户端的5900端口，在客户端执行：

       ```shell
       ssh <x11vnc-server-host> 5900:localhsot:5900
       ```

       而后客户端连接自己的5900端口即可。

  - auth加密

    ```shell
    x11vnc -display :0 -auth ~/.Xauthority  #root用户
    
    #GDM 以下将打开gdm登录界面（120是gdm的uid）
    x11vnc -display :0 -auth /var/lib/gdm/:0.Xauth
    #新版本gdm可使用：
    x11vnc -display :0 -auth /run/user/120/gdm/Xauthority
    
    #lightdm
    x11vnc -display :0 -auth /var/run/lightdm/root/\:0
    
    #sddm
    11vnc -display :0 -auth $(find /var/run/sddm/ -type f)
    ```

- 设置密码

  ```shell
  x11vnc -usepw  #生成密码文件~/.vnc/passwd
  ```

- 持续运行

  默认情况下，x11vnc将接受第一个VNC会话，并在会话断开时关闭。为了避免这种情况，可以使用-many或-forever参数启动x11vnc：

  ```shell
  x11vnc -many -display :0
  #或
  x11vnc --loop  #这将在会话完成后重新启动服务器 
  ```

## vncconfig

控制vnc的工具，在服务端执行vncconfig可以打开一个图形窗口，可在其中勾选激活客户端和服务端之间剪切版同步等功能。

## vncserver配置示例

vncserver命令中可以设置显示和操作相关参数，参数可以在vnc配置文件中配置，主要涉及`~/.vnc`下的`config`文件和`xstartup`文件（如果没有单独配置这两个文件，将使用默认的配置）。

`config`文件中的配置可在`vncserver`命令参数中指定，`xstartup`中的配置只能写在一个文件中，可使用`vncserver`的`-xstartup`参数指定文件。

`~/.vnc/config`文件配置根据名称即可获知其用途，示例如下：

```shell
# desktop=sandbox
geometry=1920x1080  #分辨率
# localhost
# alwaysshared
dpi=96
```

`~/.vnc/xstartup`文件供启动虚拟会话时使用，是一个shell文件，配置启动会话时的相关环境，最重要的是配置启动会话的桌面环境或窗口管理器，示例如下：

```shell
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1

#指定要使用什么桌面环境或窗口管理器
#session=startxfce4    #xfce
#session=startlxde     #lxde
session=gnome-session  #GNOME
#session=mate-session  #MATE
#session=startdde      #DDE(Deepin桌面)
#session=startkde      #KDE Plasma
#session=i3            #i3wm

# Copying clipboard content from the remote machine (need install autocutsel)
#autocutsel -fork

#exec $session
exec dbus-launch $session
```



# VNC客户端使用

连接虚拟会话，使用服务端的地址+端口即可，例如:`192.168.0.1:5901`（或者使用会话编号如`192.168.0.1::1`。

连接物理会话，使用5900端口，一些客户端不填写端口时默认使用5900。

# 相关问题

- 黑屏
  - VNC协议基于X，不支持wayland。
  - 没有在xstartup中执行

- dbus冲突

  > Could not make bus activated clients aware of XDG_CURRENT_DESKTOP=GNOME environment variable: Could not connect: Connection refused
  

例如安装了anaconda，它的bin目录中的dbus-daemon会与系统自带的dbus-daemon冲突。

解决方法：

- 不使用ananconda
  
- 不要自动激活ananconda或者将其加入登录后自动加载的环境变量，使用时手动加载。
  
- 提升系统原有dbus-daemon优先级
  
  复制`/usr/bin/dbus-daemon`到其他目录，在ananconda的export后面添加这个目录的PATH。例如：
  
  ```shell
    cp $(which dbus-daemon) /usr/local/bin
    #anaconda.sh是写有ananconda环境变量配置的文件
    echo "export PATH=/usr/local/bin:$PATH" >> /path/to/anaconda.sh
  ```
  
  

