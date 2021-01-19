# vnc简介

VNC 由AT&T 的剑桥研究实验室开发，可实现远程图像显示和控制。

VNC可是指一种通信协议——[Virtual Network Computing](https://en.wikipedia.org/wiki/Virtual_Network_Computing)，也代指实现这种协议的工具——Virtual Network Console（ 虚拟网络控制台）。

VNC工具分为服务端和客户端，服务端提供两种服务方式：

- 物理会话：直接显示物理显示器的图像，所有连接上的用户看到的是同一图像。
- 虚拟会话：同时运行多个虚拟会话，各个会话图像不同。

# 常见VNC实现

VNC作为一种通用协议，现有多种实现工具：

- [TigerVNC](https://www.tigervnc.org)

  TightVNC的分支，取代原TightVNC，虚拟会话使用`Xvnc`，物理会话使用`x0vncserver`。

  如今Linux发行版中最常用的VNC实现（一些发行版中安装vncserver包即是安装tigervnc）。tigervnc包含一个vnc客户端vncviewer。

- [TurboVNC](https://turbovnc.org/)

  TightVNC的分支，特点是对图形传输方面的优化。（可配合使用VirtualGL增强远程3D支持）

- [RealVNC](http://www.realvnc.com)

  2002年剑桥研究室实验室关闭，后来VNC的创始人创立的RealVNC公司开发的产品，客户端可以通过该产品的服务器连接服务端，提供商用版本，以及有一定限制的免费版本。

- [vino](https://wiki.gnome.org/Projects/Vino)及[vinagre](https://wiki.gnome.org/Apps/Vinagre)

  [GNOME](https://www.gnome.org)项目的子项目，vino为服务端，vinagre为客户端（还支持SPICE、RDP、SSH等协议）

- x11vnc

  仅为实现X11的服务端。

# VNC服务端配置

以下以tightvnc系的tigervnc为主，tightvnc命令与之类似。

re dhat/centos安装`tigervnc-server tigervnc-server-module`

## 虚拟会话

- 启动会话

  最简单方法是执行`vncserver`，它是`Xvnc`的包装脚本（`Xvnc`命令使用和`x0vncserver`类似）。

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

## vnc配置文件

**如果默认情况下连接vncserver后符合需求，无需更改相关配置文件。**

用户的vnc配置文件再`~/.vnc`目录下，主要是`config`和`xstarup`。（也有配置文件为是`~/.vnc/vncserver-config-defaults`的）

一般首次执行vncserver相关命令会创建`~/.vnc`目录并生成这两个文件。

`config`文件中的配置可在`vncserver`命令参数中指定，`xstartup`中的配置只能写在一个文件中，可使用`vncserver`的`-xstartup`参数指定文件。

### config文件

`~/.vnc/config`文件配置根据名称即可获知其用途，示例如下：

```shell
# desktop=sandbox
geometry=1920x1080  #分辨率
# localhost  #仅监听本地端口
# alwaysshared
dpi=96
```

该文件中的参数也可以在`Xvnc`和`vncserver`中直接指定，如：

```shell
vncserver -dpi 96 -geometry=1600x960
```



### xstarup文件

`~/.vnc/xstartup`文件供启动虚拟会话时使用，是一个shell文件，配置启动会话时的相关环境，最重要的是配置启动会话的桌面环境或窗口管理器，示例如下：

```shell
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1

# [ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
# [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

#vnc config tool show at the top-left in vnc window 开启后连上vnc会再左上角看到一个配置窗口
# vncconfig -iconic &

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
if [[ $session == 'gnome-session' ]]; then
  if [[ -f /etc/sysconfig/desktop ]]; then
    . /etc/sysconfig/desktop
	else
		session='gnome-session --session=gnome-classic'
	fi
fi
    

#exec $session
exec dbus-launch $session
```



# vnc安全

在互联网中开启vnc相对不安全，需要考虑明文密码及客户端与服务端之间未加密通信的问题。可以借助ssh隧道对vnc通信加密以提升安全性。

1. 如果在vnc的config文件中启用了`localhost`选项（默认注释），则其vnc会话仅监听localhost。

   也可以启用`vncserver`时，使用`-localhost`参数，若`vncserver`命令对`-localhost`参数不支持，该用`Xvnc`

   ```shell
   vncserver -localhost :1
   #或者
   Xvnc -localhost :1
   ```

   。*

2. 对vnc会话端口使用ssh端口转发（即ssh隧道）加密

   这里示例使用本地转发将vnc会话的5901端口转发到5601端口

   ```shell
   ssh -fCNL *:5601:localhost:5901 <user>@localhost
   ```

3. 访问ssh转发的端口

   以上文为例，应该访问vnc服务器的5601端口。





# VNC客户端使用

连接虚拟会话，使用服务端的地址+端口即可，例如:`192.168.0.1:5901`（或者使用会话编号如`192.168.0.1::1`。

连接物理会话，使用5900端口，一些客户端不填写端口时默认使用5900。

# 相关问题

## 黑屏

- VNC协议基于X，不支持wayland
- 缺少xorg相关包（xorg-X11-xinit，xorg-x11-xauth等等）
- xstarup中没有定义要执行的应用（比如桌面）
- 虚拟机中vnc黑屏，尝试调整虚拟软件的设置中图形相项，虚拟中使用tuborvnc也可能黑屏。

## dbus冲突

> Could not make bus activated clients aware of XDG_CURRENT_DESKTOP=GNOME environment variable: Could not connect: Connection refused

例如安装了anaconda，它的bin目录中的dbus-daemon会与系统自带的dbus-daemon冲突。

解决方法：

- 不使用ananconda

- 不要自动激活ananconda或者将其加入登录后自动加载的环境变量，使用时手动加载。

- 提升系统的dbus-daemon优先级，示例：

  ```shell
  cp $(which dbus-daemon) /usr/local/bin/
  export PATH=/usr/local/bin:$PATH
  ```



