这里是unix/linux和windows混合的lsf集群，windows作为集群计算节点加入。

可参看[lsf-mixed-cluster](https://www.ibm.com/support/knowledgecenter/SSWRJV_10.1.0/lsf_windows_using/mixed_cluster.html)

# 准备

- 与其他节点网络相通

- 关闭防火墙

- 修改主机名(hostname)

  ```powershell
  Rename-Computer $hostname
  ```

- 修改hosts文件（`Windows\System32\drivers\etc\hosts`）

- 组策略`gpedit.msc`

  - 计算机配置-windows设置-安全设置-账户策略-密码策略

    永不过期、复杂度等等

- 用户和组管理`lusrmgr.msc`

  - 用于lsf的用户组（可选）

    创建一个用户组（例如lsf）用于lsf作业（或者使用已有用户组例如Users）

  - lsf管理员

    创建一个lsf管理员，与linux上lsf管理员名字相同（最为简单）例如lsfadmin，可加入到lsf的用户组和Administrators用户组。





# 安装

按照窗口中的提示选择。主要注意：

- 加入其他集群角色选择

  一个以unix/linux为主节点(master)，且集群中含有windows节点的混合集群中，需要有一台windows节点作为server host，其他windows节点可以选择为as a server host，或者as a clients hosts（在设置为server的windows主机上建立ad域服务，所有设置为clients的windows主机同步server上域的用户信息即可）。

  

  题外话：如果将该windows主机作为一个集群的主节点，则在安装时选择 as a master of new cluster字样。

  

  混合集群中主要涉及用户的问题，可参看[lsf-user-mapping](https://www.ibm.com/support/knowledgecenter/en/SSETD4_9.1.2/lsf_windows_using/users_lsf_windows.html)。

  

- 填写集群主节点时，使用主机名而非IP地址。

  

安装后重启windows节点。

# 配置

## 添加windows节点到集群

- 混合集群的linux管理节点编辑以下文件，添加相关信息

  - lsf.cluster.*clustername*   （这里的clutername是集群的名字）
  
  在ClusterAdmins中添加windows主机上的lsf管理员用户，以`域名\用户名`格式（例如`c01\lsfadmin`）
  
  ```shell
    Begin   ClusterAdmins
    Administrators = lsfadmin c01\lsfadmin
    #如果混合集群中多个windows主机不使用ad同步用户到一个域，即安装时这些主机都选择了as a server
    #则需要将这些主机全部填写
    Administrators = lsfadmin c01\lsfadmin c02\lsfadmin
    End    ClusterAdmins
  ```
  
- lsf.cluster
  
  添加windows主机的域：
  
  ```shell
    LSF_USER_DOMAIN=c01
    #如果混合集群中多个windows主机不使用ad同步用户到一个域，即安装时这些主机都选择了as a server
    #则需要将这些主机全部填写
    LSF_USER_DOMAIN=c01:c02:c03
  ```

linux主节点和新注册到集群的windows节点执行`lsfrestart`，并在在shell中使用lsid、bhosts等检查集群运行状态。如有问题，使用`lsadmin ckconfig -v`和`badmin ckconfig -v`检查。

## 注册windows节点的用户到集群

注册用户主要参看[lsf-user-mapping](https://www.ibm.com/support/knowledgecenter/en/SSETD4_9.1.2/lsf_windows_using/users_lsf_windows.html)的Mixed cluster 部分，了解混合集群中用户映射相关概念。



注册管理用户：

---

在linux管理节点或者windows节点上使用`lspasswd`将windows节点上的lsf管理用户注册到集群：

```shell
#lspasswd -u "domain\admin" -p password
#注册这些as  a server的windows节点  如果所有windows节点中只有一个作为server，其余作为client，加入到server的域中，则只注册该域即可，例如域为lsf，注册lsf\lsfamdin即可。
lspasswd -u "c01\lsfadmin" -p lsfadminpwd
```



注册普通用户：

---

建立普通用户，可在linux管理节点和windows计算节点上建立相同的用户名，而且需要按照上面的方法使用`lspassword`注册用户到集群中。

该操作的目的是进行跨平台提交任务（例如从linux节点提交任务到windows节点），如果不进行跨平台提交任务，也可以忽略该步骤。

不同系统不能执行同一个任务（跨节点任务不能在不同系统上执行），linux节点向windows节点提交任务，需要使用`-m`指定节点。



如果在一个linux或windows节点上向一个windows节点提交作业后，作业状态为`PEDN`，`PENDING REASONS`信息为` Unable to determine user account for execution;`（可使用`bjobs -l <job id>`查看`PENDING REASONS`下同）：

原因是目标windows节点上没有该用户(提交作业的用户)，需要在windows节点创建用户。

在windows上使用命令行创建用户test（windows节点主机名为c01，用户创建到c01上，未使用域管理，用户密码为test_pwd）的示例：

```powershell
net user test  test_pwd /add
lspasswd -u "c01\test" -p test_pwd
```



如果在一个linux或windows节点上向一个windows节点提交作业后，作业状态为`PSUSP`，`PENDING REASONS`为`Failed to get user password`：

原因是未执行`lspasswd`将该作在的目标windows节点上的执行用户注册到集群中，需要使用`lspasswd`注册该用户到集群中。

注册test用户（该用户位于的windows节点主机名为c01，用户密码为test_pwd，密码为testpwd）到集群的示例：

```shell
lspasswd -u "c01\test" -p testpwd
```



如果在windows节点向自身提交作业现作业状态为`PSUSP`，`PENDING REASONS`为`Failed to get user password`：

原因是windows为使用AD域，该用户为本地用户，其向自身节点提交作业使用的用户名形如`.\test`而非`c01\test`，即使注册过`c01\test`为无效，在windows本地提交时，只需要在该windows节点上将该用户注册到集群中即可。

在windows节点注册`.\test`用户示例：

```shell
lspasswd -u ".\test"  #或者执行lspasswd ,再按照提示输入密码
```

