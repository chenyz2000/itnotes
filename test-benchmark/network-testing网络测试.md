# 网络监控工具

- atop

- iftop

- nethogs

- nload

- [mtr](#mtr)

# 测试工具

## 网络可用性测试

主要用以监测和诊断网络是否连通。

### ping

`ping <host>`

### curl

ping被禁止时可以用curl检查端口的可用性

`curl <host>:<port>`

### telnet

`telnet <host> <port>`

## 路由追踪

### traceroute和tracepath

用于追踪并显示报文从数据源（source）主机到达目的（destination）主机所经过的路由信息，给出网络路径中每一跳（hop）的信息。

traceroute专门用户追踪路由，追踪速度更快；tracepath可以检测MTU值。

另*windows下有tracert*。

```shell
tracepath [-n] z.cn
traceroute z.cn
```

### mtr

mtr是My traceroute的缩写，是一个把ping和traceroute并入一个程序的网络诊断工具。

直接运行`mtr`会进入ncurses编写的实施监测界面。此外还有该工具的其他图形界面前端实现，如mtr-gtk。

```shell
mtr --report -c 10 -n z.cn  #检测z.cn的traceroute
```

## 网络性能测试

### iperf和netperf

二者均是客户端-服务端模式（C/S client-server），先在服务端开启监听服务，然后客户端向服务端发起连接。

简单示例（更多参数查看帮助）：

- iperf

  - 服务端：`iperf -s `
  - 客户端：`iperf -c <server> `
    - `-t`  持续时间
    - `-i`  间隔时间
    - `-w`  TCP window 大小
    - `-u`  UDP测试
    - `-P`  多线程

  ```shell
  iperf -s [-p port] [-i 2]  #p监听的端口 i报告刷新时间间隔
  iperf -c <server> [-n filesize] [-p port] [-i 2] [-t 10]
  ```

- netperf

  - 服务端：`netserver `
  - 客户端：`netperf -H <server>`

  ``` shell
  netserver [-p port] [-L localip]  #p端口 L本地ip
  netperf -H <server> [-p port] [-m send_data_size] [-l total_time] #m发送数据大小  l测试总时间
  ```


## infiniband测试

- ibping 一般附带在Infiniband套件中，比通常的Ping功能更多。

  - 服务端 `ibping -S`
    获取服务端的`port_lid`

    ```shell
    ibv_devinfo
    #port_lid=$(ibv_devinfo|grep port_lid|grep -oE [0-9]+)
    ```
    
  - 客户端 `ibping -L <server port_lid>`


- 查看ib信息

  - `ibnodes`  同一网络中的节点信息
  - `ibstat`或`ibstatus`  基本信息和状态
  - `ibv_devices`  ib卡GUID信息

- 带宽和延迟测试`ib_write_bw` 、`ib_send_bw` 和 `ib_send_lat` 

  - 确保一台服务器已经开启opensmd服务，所有服务器启用了openibd服务，使用`ibstat`查看ib卡是否已经就绪，节点互相可ping或ibping通信。

  - 一台服务器作为server，执行：

    ```shell
    #-c连接方式（可选） 
    #-d 指定设备(可选，多个ib卡时使用)
    #-i 端口（可选，多个端口连接且需要测试指定端口时使用）
    #ib_send_bw -a -c UD -d mlx5_0 -i 2
    ib_send_bw 
    ```

  - 一台服务器为客户端，执行：

    ```shell
    ib_send_bw <server>  #server的hostname或ip等
    ```

- qperf  测试RDMA性能

  - 服务端 `qperf`

  - 客户端`qperf <server> tcp_bw`  (ud_bw测试udp）

    bw带宽，lat延迟。

