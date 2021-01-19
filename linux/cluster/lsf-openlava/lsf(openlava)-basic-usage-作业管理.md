# 简介

LSF和openlava

> IBM Spectrum LSF是一款分布式集群管理系统软件，负责计算资源的管理和批处理作业的调度。

> openlava兼容IBM Spectrum LSF的工作负载调度器，支持各种高性能计算和分析应用。

# 程序管理

以下命令可能需要root（或sudo）用户才能执行。

```shell
lsid  #查看集群说明信息
#启动/停止程序
openlava start  #启动
openlava stop  #停止
openlava status  #状态
```



# 获取信息

术语：

- cluster：集群
- host：主机（集群中的一个节点，一般是指一台单独的设备）
- queue：队列（同一类型的作业的集合，默认按作业提交的先后顺序排序执行，类似显示中的排队）



## 节点状态bhosts

- 节点信息

  ```shell
  lshosts  #各节点的系统信息（cpu内存等）
  
  bhosts   #各节点状态
  bhosts -l  <主机名>  #展示指定主机的信息
  
  lsload  #各节点的负载信息
  ```

  `bhost`的STATUS栏展示节点状态：

  - ok  可用

    可接受新的作业的正常状态

  - unavail  不可用

    可能原因：主机离线；LIM和sbatchd不可达（网络通信问题，例如网络不稳定，防火墙阻隔等）。

  - unreach  无法连接

    可能原因：LIM在运行，但是sbatchd不可达。

  - close  关闭

    不接受新的作业

    可能原因：该节点的最大作业数被设置为0；该节点被关闭；该节点正在运行的作业数量以达到上限。
    
    使用`bhosts -l 主机名`可查看具体原因。

- 开关节点

  *root或配置中定义的`ClusterAdmins`中的管理员用户才有权执行。*
  
  ```shell
  badmin hopen  <主机名> # all可开启所有主机
  badmin hclose <主机名> # all可关闭所有主机
  ```



## 队列信息

- 队列信息queues

  ```shell
  bqueues          #查看所有队列
  bqueues <队列名>  #查看某个具体队列的信息
  ```

- 开启或关闭队列

  *root或配置中定义的`ClusterAdmins`中的管理员用户才有权执行。*
  
  ```shell
  badmin qopen <队列名>
  badmin qclose <队列名>
  ```



## 用户/用户组信息busers

展示用户和用户组相关信息，主要包括最大可用资源、当前运行作业数量、等待作业数量等。

```shell
busers all         #所有用户
busers <username>  #某个用户
buser              #当前用户
```



# 管理作业

术语：

- JOB: 作业，用户通过调度器来管理运行的进程任务，每个作业有一个唯一的数字编号（job id）。



## 提交作业bsub

**注意：root用户不能提交作业！**

提交作业后，调度系统会为该作业分配一个编号，后续查询、管理作业均可使用该作业编号进行指定操作。

`0`号作业表示所有作业。

作业提交方式有三种：

- 命令行输入完整参数提交 

  一次性输入完成的参数

- bsub脚本提交

  编写可被bsub识别的任务脚本，使用`bsub < jobfile`的方式提交

- 交互式提交

  输入bsub后回车，进入交互式命令行添加参数

### 命令行输入完整参数提交

```shell
bsub [参数] <命令>  #<命令>指要运行的命令/脚本/程序。

#最常用的参数组合如下
bsub -q <队列名> -m <机器名> -n <线程数> -o <标准输出文件> -e <标准错误输出文件> -J <作业名> <命令>

#提交示例
bsub sleep 100 #随机选择节点单线程执行

bsub -e %J.err.log.txt -J mytestjob "python test.py" #提交任务运行python test.py

bsub -e %J.err -o %J.out -J myjob -n 16 mpirun vasp  #16线程并行执行vasp

bsub -M 1024 -R "select[mem>512] rusage[mem=512]" sleep 1000 #指定需求的内存

bsub -m c01 -n 5 test.sh  #指定在c01执行test.sh

bsub -Ip vim testfile.txt  #分配一个节点用以打开vim
```



### bsub脚本提交

编写可被bsub识别的提交脚本，以`#BUSB`开头的行定义bsub的参数，示例文件job1：

```shell
#BSUB -L /bin/bash  #shell
#BSUB -n 2          #cpu数量
#BSUB -J testjob    #任务名字
#BSUB -o %J.out.txt #记录标准输出的文件
#BSUB -e %J.err.txt #记录标准错误输出的文件

#以下是要执行的命令
sleep 233
```

提交job1：

```shell
bsub < jobs.sh
#等同于 bsub -n 2 -J testjob -o %J.out.txt -e %J.err.txt "sleep 233"
```



### 交互式提交

执行`bsub`命令进入交互式命令行，依次输入参数和执行的命令，最后按下<kbd>Ctrl</kbd> <kbd>d</kbd>退出交互式环境并提交。

> [hpcadmin@master ~]$ bsub
>
> bsub> -n 2
>
> bsub> -J testjob 
>
> bsub> sleep 233
>
> bsub> Job <121> is submitted to default queue <normal>.



---

bsub常用参数：

- `-q <队列名>`  指定要提交到的队列（可选）

  如不指定则提交到默认队列。

- `-m <节点名>`  提交到指定节点（可选）

  如不指定将随机选择合适的节点。

  **注意：**

  ​	在LSF混合集群中（例如linux+windows的混合集群），如不使用`-m`指定节点，作业无法提交到与当前（执行提交命令的主机）操作系统不同的节点上。

  ​	例如，在linux节点上提交任务`bsub -n sleep 233`，该作业不会被分配到一个操作系统为windows的计算节点上。假如c11节点的系统为windows，可以使用`bsub -m c11 <cmd>`指定当次作业在c11节点运行。

- `-n <线程数>`  指定使用的线程数（可选）

  如不指定默认为1。

  提示：该处`-n`指定的线程数是任务调度系统**分配给该作业的最大可用线程资源**，与该作业执行的程序是否多线程并行执行无必然联系，程序并行执行需要其自身进行并行调用操作。

  ```shell
  #分配了8线程资源 mpirun不带参数默认使用所有线程资源运行vasp_std
  bsub -n 8 mpirun vasp_std  #等同于#bsub -n 8 mpirun -n 8 vasp_std
  #虽然分配了8线程供其使用，但vasp_std是单线程执行 未调用mpi
  bsub -n 8 vasp_std
  ```

  使用了-n指定后，`mpirun` 就无需再指定其自身的`-n`参数。不建议使用以下方式调度，其会造成实际使用资源与调度器统计的资源发生出入：

  ```shell
  #为其分配了8线程资源 但mpirun指定只用4线程并行
  bsub -n 8 mpirun -n 4 vasp_std
  #只为其分配了8线程资源 mpirun要求超出了调度器分配的资源范围 
  bsub -n 8 mpirun -n 16 vasp_std
  ```

  

- `-o <标准输出文件>`  指定作业执行中的**标准输出**（stdout）信息文件

  如不指定，无标准输出文件。

  作业执行中的相关输出信息会写入该文件中，文件名字中可使用`%J`表示作业的编号（如`%J.txt`）。

  

- `-e <标准错误输出文件>`  指定作业执行中的**标准错误输出**（stderr）信息文件

  如不指定，无标准错误输出文件。

  作业执行中的相关**错误输出**信息会写入该文件中，文件名字中可使用`%J`表示作业的编号。

  

- `-J <作业名>`  指定作业名

  如不指定， 如不指定默认为提交作业执行的命令名。
  
  
  
- `-L </shell-path>`  指定shell

  


- `-i`  指定作业的输入文件（需要指定作业输入文件时使用）
- `-Ip`  提交一个交互式作业并开启一个伪终端（交互式任务时必选）



- `-M <mem-size>`  限制内存大小
- `-R <request-info>`  指定资源请求，具体用法使用`man bsub`查看帮助（在man中搜索`-R`查看其使用实例）
- `-W [hours:]minutes[/host_name | /host_model]`  限制作业运行时间（超时会被bkill）



## 查询作业

提示：

- 可使用大括号扩展特性（例如`{102..108}`）操作一个编号区间的作业。

### bjobs和bhist查看作业记录

```shell
bjobs  #列出所有未完成作业
bjobs -r  #查看正在运行的作业
bjobs -p  #查看排队等待的作业
bjobs -d  #查看已经完成的作业

bjobs -u <username>  #查看某个用户的作业信息
bjobs -u all  #查看所有用户的作业

#加上作业编号可以查看某个具体的作业
bjobs 135  #查看135号作业（即使该作业已经完成也可以查看）
bjobs -l 135  #查看135号作业详情 （作业完成5分钟以后只能用bhist查看）
bjobs {111..115}
bjobs -p 135  #查看处于排队状态的135号作业（可了解其排队原因）

bhist　#查看作业历史
bhist -a #查看所有历史提交的作业（包括未完成）
```

bjobs/bhist常用参数

这些参数后如不指定作业编号，将列出所有符合条件的所有作业的信息。

- `-r`  查看运行中（runing）的作业

- `-p`  查看排队中（pending）的作业

- `-d`  查看已完成（done）的作业

- `-l`  查看作业详情

  一个作业完成5分钟后，只能使用bhist -l查看作业详情（之前作业详情是存储在内存中，完成后5分钟将被从内存中清除）。

- `-u`  查看某个用户的作业（如果值为`all`即查看所有用户的作业）



### bpeek查看运行中作业的输出

查看运行中作业的标准输出（stdout）和标准错误输出（stderr）。`

```shell
#bpeek查看正在运行的作业的输出信息
bpeek  #查看最近一个提交作业的输出信息
bpeek 135  #查看135号作业输出信息
```



### 作业状态

`bjobs`展示的状态信息中，STAT一栏为作业状态：

- DONE  已完成
- RUN     运行中
- PEND   排队等候调度
  - PSUSP  作业在排队中被挂起
  - USUSP  作业在计算中被挂起
  - SSUSP  作业被调度系统挂起

一个作业需要满足以下条件才能执行：

- 到达用户指定的时间（如果用户指定了开始时间）
- 合格的主机负载
- 队列中有符合执行条件的主机



### 常见排队原因

- > User has reached the pre-user job slot limit of the queue

  用户作业达到了排队中作业所在队列的**个人作业进程数上限。**

  此队列中用户正在运行的作业有计算结束，才会再分配后续的排队作业。

- > The slot limit reached; 4hosts

  排队中作业达到了所在队列**可使用节点数的上限。**

  此队列中所有用户正在运行的作业有计算结束，才会再分配此队列中排在最前边的作业。

- > The user has reached his job slot limit

  用于已运行的**作业数达到了系统规定的上限**。

  需已运行的作业有新的计算结束，排队中的作业才会进入系统调度。

- > The queue has reached its job slot limit

  队列中已经运行的所有作业达到了系统上**队列总作业进程数的上限**。

  需该队列中已运行的作业有新的计算结束，才会调度该队列中排在第一位的作业。



## 调整未完成作业

### 更改作业提交参数bmod

 只能在作业尚处于排队中时，已经运行的作业无法再更改提交或计算参数。

```shell
bmod -q high 123  #将123号作业编进名为high的队列中
bmod -J new_name 123  #给123号作业重新起名为new_name
```



### 更改作业执行顺序btop/bbot

**只能修改正在排列的作业**，对已经开始运行的作业无效。

```shell
btop 123  #将123号作业移动到排队的顶部
bbot 123  #将123号作业移动到排队的底部
```



### 挂起未完成作业bstop

```shell
bstop  <作业编号>
bstop 1234  #删除1234号任务
```



### 恢复挂起的作业bresume

```shell
bresume  <作业编号>
bresume 1234  #删除1234号任务
```



### 删除作业bkill

```shell
bkill  <作业编号>
bkill 0 #删除所有作业
bkill 1234  #删除1234号任务
```



# 排错

## 作业工作目录被设置为`/tmp`

http://www-01.ibm.com/support/docview.wss?uid=isg3T1014883

linux下，调度器由于未找到相关的环境变量设定以下变量的值，于是将这些变量的值设置为`/tmp`。

- `$LS_SUBCWD`

  提交任务的home dir，默认是PWD变量的值，如果没找到PWD变量，则设置为CWD变量的值

- `LS_EXECCWD`

  交任务的work dir，默认是执行提交命令时文件夹

可以设置以上环境变量的值，以确保工作目录正确。



windows下(lsf)，`LS_SUBCWD`会被设置到用户目录下的`AppData\Local\Temp`，`LS_EXECCWD`会被设置到LSF安装目录下的`tmp`。

> LS_EXECCWD: Sets the current working directory for job execution. 
>
> LS_SUBCWD: This is the directory on the submission when the job was submitted. This is different
> from PWD only if the directory is not shared across machines or when the execution account is
> different from the submission account as a result of account mapping.

