# 准备工作

如果非单一节点的情况：

- 选定一个节点作为openlava服务器（管理节点），配置该节点到其他节点的ssh密钥登录。
- 确保所有节点使用同一用户运行openlava（可使用nis等服务管理集群用户）。
- 在管理节点的hosts文件（`/etc/hosts`）中加入其他节点的hostname解析
- 关闭各个节点防火墙或者开放相应的端口（在openlava的etc目录下lsf.conf中可查看各个服务的监听端口）

# 编译安装

编译及运行所需依赖

- gcc
- ncurses-devel
- tcl-devel

修改集群说明信息(lsid)，编辑`lsf/lsftools/lsid.c`中相关说明文字。

以编译安装安装到`/opt/openlava`为例，下同。

```shell
dest=/share/openlava
./configure --prefix=$dest
make
make install

#生成配置文件
./config.status
\cp config/* $dest/etc -f
cd $dest/etc
\rm Makefile* *.in -f
```

# 基本配置

- 执行用户和环境变量

  ```shell
  dest=/share/openlava
  user=hpcadmin
  #创建运行openlava的用户 r创建为系统用户 M不创建家目录 s指定shell
  useradd -M /sbin/nologin $user
  #make -C /var/yp  #一般会使用用户信息管理工具如yp
  chown -R $user $dest
  sed -i s/openlava/$user/ $dest/etc/lsf.cluster.openlava
  
  #环境变量
  cd $dest/etc/
  chmod +x $dest/etc/openlava*
  source ./openlava.sh
  ./openlava.setup
  ln -sf $dest/etc/openlava $dest/bin/
  
  #设置开机自启动
  systemctl enable openlava
  ```

- 主配置文件`lsf.conf`

  设置openlava环境变量、监听端口、日志等。

  - 主解点列表`LSF_MASTER_LIST`，值为集群主节点的主机名。

  - 日志级别`LSF_LOG_MASK`取值：
    - `LOG_WARNING`
    - `LOG_DEBUG`（如果hpc的Administrator用户是root，则日志级别为DEBUG）
    
  - `bjobs`中`EXEC_HOST`显示为单行模式：`LSB_SHORT_HOSTLIST=1`

    

- 共用默认配置信息`lsf.shared`

  设置集群配置文件默认值，提供给`lsf.cluster.<name>`文件（name为集群的名字，可在`lsf.shared`中定义该集群的各项默认值）使用。

  

- 某个集群的配置文件`lsf.cluster.openlava`（openlava为默认的集群名字，可更改）

  部分内容如下：

  ```shell
  Begin   ClusterAdmins
  Administrators = openlava #运行openlava服务的用户
  End    ClusterAdmins
  
  Begin   Host  #主机列表
  HOSTNAME    model    type  server  r1m  RESOURCES
  #yourhost IntelI5    linux   1      3.5    (cs)
  master       !      !    1      !    !
  c01          !      linux    1      3.5    (cs)
  End     Host
  ```

  主机列表中，第一行被认为是管理节点，其后一一添加其他节点。

  `!`表示使用默认，默认值可以在`lsf.shared`文件中设置。

# 启动服务

```shell
#所有节点启动openlava
openlava start
#查看运行状态
openlava status
#检查配置文件
badmin ckconfig
lsadmin ckconfig
```

- 重新应用配置

  在未停止openlava服务而修改过配置文件后使用

  ```shell
  badmin reconfig
  lsadmin reconfig
  ```

- 运行中添加新节点

  1. 参照上文在新节点部署好openlava并启动

  2. 在管理节点使用lsaddhost添加新节点并重启应用配置

     ```shell
     lsaddhost <hostname>
     badmin reconfig
     lsadmin reconfig
     ```



# 排错

- 查看log目录

  查看配置文件：

  ```shell
  badmin ckconfig
  lsadmin ckconfig
  ```

- 节点的`openlava status`各项服务正常启动，但状态为`unreach`，查看该节点`sbatch`日志提示`Unable to reach slave batch server`

  关闭防火墙或放行相关端口。
  
- 注意各个节点的openlava/lsf的管理员uid是否一致。

- 如果hosts文件中，某个IP对应有多个hostname，需要将lsf.cluster.xx文件中使用的主机名优先解析。例如主机192.168.1.1设置了主机名g0101和主机名c01，在lsf.cluster.xx中填写的c01，那么hosts文件中就要将c01写在最前面。

  ```shell
  192.168.1.1 c01 g0101
  ```

- bhosts中MAX值为1（而实际给予的值比1大）

  查看log目录中的文件

  lim日志提示：

  > loadEvents: unexpected error while reading lim.events: Bad event in lim.events

  删除work/lim.events文件

  