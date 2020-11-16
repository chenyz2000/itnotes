[TOC]

# install和cp

一些程序安装脚本以及Makefile里会用到install进行文件复制，它与cp主要区别：

- 如果目标文件存在，cp会先清空文件后往里写入新文件，而install则会先删除掉原先的文件然后写入新文件

  这是因为往正在使用的文件中写入内容可能会导致一些问题，比如写入正在执行的文件可能会失败，已经在持续写入的文件句柄中写入新文件会产生错误的文件。使用  install先删除后写入（会生成新的文件句柄）的方式去安装就能避免这些问题

- install命令会恰当地处理文件权限的问题。

  - `install -c a /path/to/b`  把目标文件b的权限设置为`-rwxr-xr-x`
  - `install -m 0644  a /path/to/b`  把目标文件b的权限设置为`-rw-r--r--`

- install命令可以打印出更多更合适的debug信息，还会自动处理SElinux上下文的问题。

# 自动打开gui终端并执行命令

例如想打开一个gnome-terminal终端，打开终端后直接进入python交换环境：

```shell
gnome-terminal -- python
```

# 系统环境

- 获取当前发行版信息

  ```shell
  echo $(. /etc/os-release;echo $NAME)
  ```

- `$MACHTYPE`  架构及操作系统等信息（例如输出x86_64-pc-linux-gnu）

- `$EDITOR`  默认编辑器（某些软件会调用例如git commit时）

# 判断命令是否可用

判断某个命令是否可用，即判断是该命令在$PATH中。

以检查命令ssh是否可用为例，以下方法均可在ssh存在的情下返回一些内容，code为0，不存时返回值为空 ，code为1：

- `command -v ssh` 
- `which ssh 2>/dev/null`
- `type 2>/dev/null`
- `hash ssh 2>/dev/null`



# shell脚本相关

- `sh`中没有`source`

- `$SHELL`  当前shell名称

- shell文件格式化工具`shfmt`

- 在脚本最前面使用`unalias -a`取消所有alias避免alias而可能造成的问题。

- `$BASHPID`  当前bash的pid（非bash终端变量名不同）

- 更加安全的执行脚本`set -eu`

  - 避免引用未定义变量造成的问题，在脚本最上方添加：`set -u`

    例如`rm -rf $xx/`，而`$xx`未定义，结果成了执行`rm -rf /`。

  - 遇到错误行自行退出，在脚本最上方添加一行：`set -e`

    某行执行后返回值不为0自行退出，避免继续执行其后的代码，例如某行执行的命令书写错误而执行失败。

## seq序列化输出

seq命令产生从某个数到另外一个数之间的所有整数。

```shell
seq [选项]... 尾数
seq [选项]... 首数 尾数
seq [选项]... 首数 增量 尾数
```

如果不指定首数，则首数默认为1；如果不指定增量，则增量默认为1。

常用选项

- `-f`, `--format=格式`        使用printf 样式的浮点格式
- `-s`, `--separator=字符串`   使用指定字符串分隔数字（默认使用：`\n`）
- `-w`, `--equal-width`        在数字添加0补充位数 使得宽度相同



seq输出的数字每个占用一行，因为默认的分隔符是换行符，可指定分隔符：

```shell
seq -s " " 3 #一个空格分隔 输出一行 1 2 3
seq -s "" 3  #无分隔符 输出一行123
```

提示：使用`{m..n}`展开也能输出数字m到n的所有整数，所有数字只占用一行，两个数字间使用空格分隔；可使用`seq m n|xargs`将输出数字合并为一行，两个数字间使用空格分隔。

```shell
seq -w 99 101  #倒序生成数字
```

# 用户相关

- `$USER`或`whoami`  当前用户名

- `id $USER`  用户的uid和gid信息

- `$HOME` 用户家目录 

  ```shell
  grep ^$USER: /etc/passwd |cut -d ":" -f 6  #or $(whomai)
  getent passwd | grep ^$USER: |cut -d ":" -f 6  #or $(whomai)
  ```

- `getent`  从管理数据库取得条目（参看`getent --help`）

- 修改密码（非交互式）

  - passwd的`--stdin`参数（某些发行版的passwd可能不支持）

    ```shell
    echo "new_pwd" | passwd --stdin [username]
    ```

  - chpasswd 读取文件或标准输入

    创建一个含有用户名和密码的文件，每行一个用户信息，使用`:`分隔用户名和密码，形如`username:password`，例如该文件为`/tmp/pwds`，内容为：

    > root:123456
    > user1:123456
    
    使用chpasswd读取该文件：

    ```shell
  chpasswd < /tmp/pwds
    ```
    
    从标准输入读取：
    
    ```shell
    chpasswd <<EOF
    user1:pwd1
    EOF
    ```

# 文件相关

- 获取文件的绝对路径/软链接的原始文件的路径

  ```shell
  readlink -f link-file-name   #软链接的原始文件的绝对路径
  readlink -f `dirname $0`     #当前脚本文件的绝对路径
  ```

- 当前执行文件所在的目录

  ```shell
  dirname $(readlink -f "$0")
  ```

- 文件绝对路径

  ```shell
  realpath xxx  #xxx为当前目录下某文件的名字
  ```

- 从路径字符串中截取文件或文件夹的名字

  例如要获取`/home/test1/testfile`字符串中获取到`testfile`字符串

  ```shell
  basename `/home/test1/testfile`
  basename `$0`  #获取当前脚本的文件名
  ```

- 文件大小

  ```shell
  stat --format=%s <filename>  #单位为byte 或-c
  ls -lh <filename>
  ```

- 杀死一个进程以及其所有后代进程

  ```shell
  pid=1234  #1234是进程号
  [[ $pid ]] && kill -9 $(pstree $pid -p|grep -oE "\([0-9]+\)"|grep -oE "[0-9]+")
  ```

- 重复输出一个字符

  - 使用printf

    ```shell
    #打印30个*
    s=$(printf "%-30s" "*")
    echo -e "${s// /*}"
    
    #根据当前终端宽度（列数）打印一整行=
    
    #使用sed
    printf "%-${COLUMNS}s" "="|sed "s/ /=/g"
    
    #使用echo
    s=$(printf "%${COLUMNS}s" "=")
    echo -e "${s// /=}"
    ```

  - 使用seq

    根据当前终端宽度（列数）打印一整行`=`：

    ```shell
     seq -s "=" $(({COLUMNS}+1))|sed -E "s/[0-9]//g"
    ```

    seq以`=`为分隔符生成与终端宽度字符数量相等的数字（形如`1=2=3=4`）

    sed正则匹配所有数字并替换为空字符串。（`=`总比数字少1个，因此要行数基础上+1，这样再将数字去掉后`=`数量才和一行字符数量一致）


# 终端控制

获取当前终端端宽（列数）高（行数）

- 全局变量`COLUMNS`和`LINES`
- `tput cols`和`tput lines`
- `stty size`  (输出两个数字，以空格分开，前面为行数--高，后面为列数-宽）

# 未归类

- 打开默认应用 `xdg-open <file or url>`

  ```shell
  xdg-open http://localhost #使用默认浏览器访问http://localhost
  xdg-open testfile  #使用默认编辑器打开testfile文件
  ```

- 列出以`-`开头的文件，使用`--`

  ```
  ls -- -test.txt
  cat -- -test.txt
  ls -- ./-test.txt
  ```

- gzexe给脚本加密（普通文件亦可）

  ```shell
  gzexe a.sh
  ```

   例如给a.sh加密，该命令执行完成后将有两份文件，`a.sh`和`a.sh~`，带`~`的是原来的文件，不带`~`的是加密过的文件。

