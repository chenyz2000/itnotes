> Slurm是一个开源，容错，高度可扩展的集群管理和作业调度系统，适用于大型和小型Linux集群。



# 安装

下载源码，解压，编译安装。需要python3+，如果缺少依赖包，安装后重新`configure`。

```shell
./configure --prefix=/share/slurm #--sysconfdir=xx
make -j #8
make install
```

