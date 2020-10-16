[TOC]

# 查看分区blocksize

```shell
stat  <分区挂载点> 
```

在输出信息中可以看到IO block大小。

# df卡住

```shell
mount |column -t
```
找出可能引起卡死的挂载点，一般是nfs等网络挂载点,，卸载之：
```shell
umount -fl /mountedPoint  #mountedPoint换成实际挂载点
```

# text file busy

卸载分区，删除文件时提示：

>text file busy
```shell
fuser /path/to/file   #换成实际的文件路径
```
然后kill掉该进程

# 创建一个大文件
例如大小1g，路径`$HOME/file`

- fallocate

  ```shell
  fallocate -l 1g file
  sync
  ```

- truncate

  ```shell
  truncate -s 1g file
  sync
  ```

- dd

  ```shell
  dd if=/dev/zero of=$HOME/file bs=1 count=0 seek=1G
  sync
  ```

  务必小心of的值不要写错，避免抹掉重要文件。

# 删除文件后未释放空间
重启。
或者：
```shell
lsof |grep deleted
```
kill掉相关进程

确保删除文件能立即释放空间可使用：
```shell
echo > /path/to/file  #换成实际的文件路径
```
