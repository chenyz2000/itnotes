# 配置文件

检查配置文件

```shell
badmin ckconfig
lsadmin ckconfig #应当在管理节点执行 非管理节点执行会报fetal error
```

重新载入配置

```shell
badmin reconfig
```



# 主配置文件

在安装目录下的`etc/lsf.conf`

```shell
#===常规配置略 以下常用添加或修改的配置行
#bjobs/bhist精简输出 每个slot一行改为输出到一行 如8*c01
LSB_SHORT_HOSTLIST=1

#管理节点列表 有多个管理节点时配置
LSF_MASTER_LIST="master"

#实时将作业的标准输出写入
LSB_STDOUT_DIRECT=y

#接受提交作业到时间间隔
JOB_ACCEPT_INTERVAL=0

#最大作业
MBD_MAX_JOBS_SCHED=30000

#作业最大slot数量
MBD_MAX_SLOTS_SCHED=64
```



# 资源限制

资源管理配置文件`config/lsb.resources`，可调控用户在集群中可使用的资源配额。

可针对不同用户类型设置多种类型资源的使用限制。可配置的资源类型和用户类型如下：

- 资源类型（Resource types）
  - SLOT或SLOT_PER_PROCESSOR（工作槽）
  - MEM（内存）
  - SWP（交换空间）
  - TMP（临时空间）
  - JOBS（作业数量，包含RUN、SSUSP和USUSP[状态](#作业状态)的作业）
  - RESOURCE（其他共享资源）
- 用户类型（Consumer types）
  - USERS或PER_USER（用户）
    - `all`  所有用户
    - `user1 user2 ... userN`  指定的用户（以空格分隔）
  - QUEUES或PER_QUEUE（队列）
  - HOSTS或PER_HOST（主机）
  - PROJECTS或PER_PROJECT（项目）
  - LIC_PROJECTS或PER_LIC_PROJECT

每一个限制策略以Begin Limit开始，以End Limit结束，其中`~`表示从某个组里面排除某某。

限制策略示例：

```shell
Begin Limit  #限制策略开始标志
NAME=limit1  #限制策略的名字
PER_USER=all~user1  #限制用于所有用户 除了user1
HOSTS=all~c01  #限制用于所有节点除了c01
SLOTS=10  #限制作业槽---一般等于cpu数量
End Limit  #限制策略结束标志
```

限制某个用户只能使用某个节点资源示例：

```shell
#对该用户将除了指定节点c01外的所有节点都限制SLOTS为0
Begin Limit
NAME = limit_for_user1
USERS = user1
SLOTS = 0
HOSTS = all ~c01
End Limit
```

限制某个用户在某个节点上可使用的资源示例：

```shell
#用户 可用c01 c02 并限定内存cpu等
Begin Limit
NAME = limit_for_user1
USERS = user1
MEM = 10240
SLOTS = 8
HOSTS = c01 c02
End Limit
```



# 节点增删

- 增加节点

  1. 修改`/share/openlava/etc/lsb.hosts`配置文件，将新节点的`hostname`添加新节点到队列数组中

  2. 更新lsf配置

     ```shell
     lsadmin reconfig
     ```

  3. 在新计算节点上启动lsf相关服务

     ```shell
     source  /share/openlava/etc/openlava.sh
     /share/openlava/etc/openlava start
     ```

- 删改节点

参照增加节点的方法，删除和修改`/share/openlava/etc/lsb.hosts`配置，然后更新lsf配置。



# 问题排查

日志信息位于安装目录的`log/`下。

- mbatchd.log

  > GetElock: Last owner of lock file was on this host with pid <xxx>, attempting to take over lock file

  1. 将`work/logdir/lsb.events`授权(`chown`)给` $LSF_ENVDIR/lsf.cluster.xxx`中设置的`Administrators`用户。

     ```shell
     chown hpcadmin lsb.events  #例如用户名是hpcamin
     ```

  2. 重启master节点的`sbatchd`进程

     ```shell
     pkill sbatchd
     badmin hstartup
     ```

- bhosts max总是为1

  检查lsb.hosts是否限制了slot数量

  网络问题，通信不畅，执行`badmin reconfig`。

