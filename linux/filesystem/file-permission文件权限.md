# 基本权限

## 基本权限的说明

**权限所有者**，即哪些用户对文件具有权限：

| 权限范围 | 符号表示 | 说明                  |
| -------- | -------- | --------------------- |
| user     | u        | 文件所有者            |
| group    | g        | 文件所有者所在的群组  |
| others   | o        | 所有其他用户          |
| all      | a        | 所有用户（相当于ugo） |

*Linux系统中，预设的情況下，系统中所有的帐号信息记录在`/etc/passwd`文件中，每个用户的密码（经过加密）则记录在`/etc/shadow`文件中，所有的组群信息记录在`/etc/group`文件中。*



**基本权限类型**，即对文件所具有的基本权限：

| 权限类型 | 字母表示 | 数字表示 | 说明                             |
| :------- | -------- | -------- | -------------------------------- |
| 读       | r        | 4        | 文件可读；目录下文件可列出       |
| 写       | w        | 2        | 文件可写；目录下可创建和删除文件 |
| 执行     | x        | 1        | 文件可执行；目录可进入           |
| 无权限   | -        | 0        | 无权限                           |

*此处数字是八进制*

**基本权限信息**，使用`ls -l name`示例，`ls -l /etc/hosts`列出信息如下：

> -rw-r--r--. 1 root root 65 Mar 12 03:24 /etc/hosts



提示：使用`stat -c %a 文件名`可以获取以数字表示的权限信息，例如`stat -c %a /etc/hosts `返回的信息是`644`。


`-rw-r--r--`即为权限信息，按顺序解释各个符号意义如下：

- 第1位：文件类型（查看[linux文件类型](#linux文件类型)）
- 第2-10位：不同用户对该文件的权限

  - 第2-4位：文件拥有者的权限

  - 第5-7位：文件所属群组（中的用户）的权限

  - 第8-10位：其他用户的权限
- 第11位：
  - 启用了selinux，该处以点号`.`字符表示

  - 设置了ACL后，该处以加号`+`表示

    提示：以`ls -l`看到的权限信息中有`+`号时，应当用`getfacl`查看权限信息，因为该种情况下`ls -l`展示的权限信息可能是ACL MASK有效权限，参看下文[ACL权限管理](#ACL权限管理)中关于MASK有效权限的描述。



## 基本权限的修改

`chown`修改文件的所有者（用户和组），`chgrp`修改文件所属组，`chmod`修改文件权限模式。

- 以上三个命令都能用到的常用参数：
  - `-c`或`--changes`  显示更改部分信息
  - `-R`或`--recursive`  作用于该目录下所有的文件和子目录
  - `-h`  修复符号链接
  - `--reference`  以指定的目录或文件的权限作为参照进行权限设置

- chmod

  [权限范围](#权限范围)：u g o a

  `+`表示加权限，`-`表示减权限，`=`表示重设权限；也可直接使用数字模式设置权限。

  ```shell
  #chmod [参数] <权限范围>[+-=]<权限> <文件/目录>
  chmod -cR g+r /srv
  chmod -cR u+w,g+r /srv  #多条权限规则使用逗号分隔
  chmod g=rwx /srv
  chmod 775 /srv
  ```

- chown

  ```shell
  ##冒号:也可以使用点号. 组名可省略
  #chown [参数] <用户名>[:组名] <文件/目录>
  chown -R nginx.nginx /srv/
  ```

- chgrp修改所属组

  ```shell
  #chgrp [参数] <组名> <文件/目录>  #冒号:也可以使用点号.
  chgrp -cR nginx /srv/
  ```

# 特殊权限

## SUID 设置用户ID

具有SUID权限的**二进制可执行文件**在**执行中，执行者拥有与该文件所有者相同的权限**。

- 仅对二进制可执行文件有效
- 执行者对于该程序需要有可执行权限
- 该权限仅在程序执行过程中有效
- 执行过程中，执行者将具有该程序拥有者(owner)的权限。

注意：如果所有者是 root 的话，那么该文件的执行者就有超级用户的特权。

使用`ls -l`输出的10或11位信息中，如果原本第4位`x`应该出现的位置显示为`s` ，表示该文件具有SUID权限：

> [root@cent7 ~]# ls -l /usr/bin/passwd                                                                                   -rwsr-xr-x. 1 root root 27832 Jun 10  2014 /usr/bin/passwd

设置SUID示例：

```shell
chmod u+s /tmp/test.sh
```



## SGID 设置组ID

特点同SUID，SGID权限仅对该群组（group）用户有效。

使用`ls -l`输出的10或11位信息中，如果原本第7位`x`应该出现的位置显示为`s` ，表示该文件具有SGID权限：

> [root@cent7 ~]# ls -l /usr/bin/wall -a
> -r-xr-sr-x. 1 root tty 15344 Jun 10  2014 /usr/bin/wall



设置SGID示例：

```shell
chmod g+s /tmp/test.sh
```



## Sticky 设置粘滞位

Sticky权限仅对其他用户（other）有效，只用于目录。

> 只有目录内文件的所有者或者[root](https://zh.wikipedia.org/wiki/超级用户)才可以删除或移动该文件。如果不为目录设置粘滞位，任何具有该目录写和执行权限的用户都可以删除和移动其中的文件。实际应用中，粘滞位一般用于/tmp目录，以防止普通用户删除或移动其他用户的文件。

注意：设置了sticky权限后的目录，其下面的文件只是不可被其他用户移动或删除（即是其他用户对其拥有w权限），只要其他用户拥有w权限，还是可以修改文件内容的。

使用`ls -l`输出的10或11位信息中，如果原本第10位`x`应该出现的位置显示为`t` ，表示该文件具有Sticky权限：

例如`/tmp`目录

> [root@cent7 ~]# ls -l / |grep tmp                                                                                       drwxrwxrwt.   7 root root  132 Sep  9 03:28 tmp  

注意：**如果s或t以大写的S或T出现，说明原本其他用户对该目录就没有x权限，此时设置Sticky并不生效。**



设置Sticky示例：

```shell
chmod o+t /share
```



# 权限掩码 umask

**umask命令**用来设置新建文件的[基本权限](#基本权限)的掩码，一共4位。

以数字形式为例，`0755`表示新建文件

使用`777`减去umask的值，即得到新建文件的默认权限，一般。例如`umask`执行后得到`022`，则新建文件权限为`777-022=755`，即`rxwr-xr-x`。

```shell
umask #以数字形式当前的掩码 如022
umask -S #以符号方式输出掩码 如u=rwx,g=rx,o=rx 即是022

#设置掩码
umask u=,g=2,o=rwx  #umask 0750 即rwxr-x---
umask 022
```



# ACL权限管理

## ACL介绍

ACL（Access Control Lists，访问控制列表）为文件系统提供更为灵活的附加权限机制。弥补chmod/chown/chgrp的不足。

ACL 通过以下对象来控制权限：

- user  用户 对应ACL_USER_OBJ和ACL_USER

- group  群组  对应ACL_GROUP_OBJ和ACL_GROUP

- mask  掩码--最大有效权限（Effective permission, 或者说权限范围）   对应ACL_MASK

  *和默认权限`umask`类似，是一个权限掩码, 表示所能赋予的权限最大值。*

  设置了mask权限后，**使用者或群组所设置的权限必须要存在于 mask 的权限设置范围内才会生效**（未设置mask权限时不存在该种限制）。

  例如：使用chmod设置某文件mask为r，则无法设置该文件的user或group权限为rw或rwx。

  可使用setfacl设置大于mask范围的权限，设置后mask最大权限值被变更为新设置的权限值。

- other  其他用户  对应ACL_OTHER

  > ACL_USER_OBJ：相当于Linux里file_owner的permission
  > ACL_USER：定义了额外的用户可以对此文件拥有的permission
  >
  > ACL_GROUP_OBJ：相当于Linux里group的permission
  > ACL_GROUP：定义了额外的组可以对此文件拥有的permission
  >
  > ACL_MASK：定义了ACL_USER, ACL_GROUP_OBJ和ACL_GROUP的最大权限
  >
  > ACL_OTHER：相当于Linux里other的permission



## getfacl和setfacl

getfacl获取当前权限信息

```shell
getfacl <file>  #获取文件的权限信息

setfacl [-bkndRLP] { -m|-M|-x|-X ... } <acl规则>
#设置文件权限示例： set -m <u|g|o|m]:[name]:[rwx-] <file>
```

setfacl设置权限

- 参数

  - 设置规则的参数
    - `-m`或`--modify`  设置后面的acl规则
    - `-M`或`--modify-file`  从文件或标准输入读取acl规则
    - `-R`或`--recursive`  递归设置后面的acl规则，包括子目录
    - `-d`或`--default`  设置默认acl规则 （子文件将继承目录ACL权限规则）

  - 删除规则的参数

    - `-x`或`--remove`  删除后面的acl规则
    - `-X`或`--remove-file`  从文件或标准输入读取acl规则
    - `-b`或`--remove-all`  删除全部的acl规则
    - `-k`或`--remove-default`  删除默认的acl规则  （子文件将继承目录ACL权限规则）
    -  `--set`  从指定文件（可指定多个）中读取acl规则
      - `--set-file=file`  从文件中读取acl规则
      - `--mask`  重新计算有效权限
    - `-n`或`--no-mask`  不要重新计算有效权限
    
    注意：最基本的ugo三个规则不能删除。

- 规则写法：`default:用户类型:名称:权限` （default也可简写为d）

  default也可简写为d，设置默认权限，目录设置默认权限后，目录下新建的文件/子目录将**继承设置的权限**。

  用户类型即上文所述的u g m o （user/group/mask/others）；

  名称即user的用户名和和group的组名**，mask和others无对应名字，该项留空**；

  权限即`rwx-`。
  
  ```shell
  #示例
  setfacl -m u:http:r-- /srv/index.html
  setfacl -Rm d:u:admin:rwx /srv #srv下新建的文件均继承设置的u:admin:rwx
  setfacl -m m::r-x /home
  ```

# 扩展属性 extended attr

Extended Attributes，以下简称EA，是区分于文件属性、文件的扩展出来的属性。

EA可以给文件、文件夹添加额外键值对，以键值对地形式将任意元数据与文件i节点关联起来。键和值都是字符串并且有一定长度地限制，是完全自定义的属性。

- 扩展属性模式：
  - a：让文件或目录仅供附加用途。
  - b：不更新文件或目录的最后存取时间。
  - c：将文件或目录压缩后存放。
  - d：将文件或目录排除在倾倒操作之外。
  - i：不得任意更动文件或目录（不能被删除、改名、设定链接关系，不能写入或新增内容）。
  - s：保密性删除文件或目录。
  - S：即时更新文件或目录。
  - u：预防意外删除。

- 查看属性`lsattr <文件|目录>`

- 设置属性`chattr 选项 <文件|目录>`

  - `-R`：递归处理，将指令目录下的所有文件及子目录一并处理；
  - `+<属性>`：开启文件或目录的该项属性；
  - `-<属性>`：关闭文件或目录的该项属性；
  - `=<属性>`：指定文件或目录的该项属性。
  
  ```shell
  chattr +i /etc/hosts
  ```
  
  