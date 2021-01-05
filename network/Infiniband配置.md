# infiniband虚拟化

参考文档 https://community.mellanox.com/s/article/howto-configure-sr-iov-for-connect-ib-connectx-4-with-kvm--infiniband-x

```shell
#!/bin/bash
#1----for oepnsm server
if [[ $( systemctl is-enabled opensmd) == 'enabled' ]]
then
	echo "virt_enabled 2" > /etc/opensm/opensm.conf
	systemctl restart opensmd
fi

#2----for openibd nodes
#enable sr-iov and vmx virtual in BIOS(UEFI setup)
#add  intel_iommu=on iommu=pt  to /etc/default/grub CMDLINE,
#redhat uefi mode:
#grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg #centos is centos/grub.cfg
#redhat bios (some distro uefi mode):
#grub2-mkconfig -o /boot/grub2/grub.cfg

vf_nums=1 #how many virtual ib devices will be created


    echo Follow >/sys/class/infiniband/mlx5_0/device/sriov/0/policy

    cat /sys/class/infiniband/mlx5_0/device/sriov/0/policy

    i=0
    while [ $i -lt $vf_nums ]; do
        #virtal ib device defautl GUID is 00:00:00:00:00:00:00:00
        #eg. hostname is c10 , host_num is c10
        port_id=11:11:11:11:11:11:$(echo $HOSTNAME | grep -oE [0-9]+):${i}0
        node_id=11:11:11:11:11:11:$(echo $HOSTNAME | grep -oE [0-9]+):${i}1

        echo $port_id >/sys/class/infiniband/mlx5_0/device/sriov/$i/port
        echo $node_id >/sys/class/infiniband/mlx5_0/device/sriov/$i/node

        #find the id :ls /sys/bus/pci/drivers/mlx5_core/
        pci_id=$(lspci | grep -i mellanox | grep -v 00.0 | sed -n "$((i + 1))p" | cut -d " " -f 1)
        echo ===device $((i + 1)) PCI: $pci_id===
        echo 0000:$pci_id >/sys/bus/pci/drivers/mlx5_core/unbind
        echo 0000:$pci_id >/sys/bus/pci/drivers/mlx5_core/bind

        echo "port_id:"
        cat /sys/class/infiniband/mlx5_0/device/sriov/$i/port
        echo "node_id:"
        cat /sys/class/infiniband/mlx5_0/device/sriov/$i/node

        let i+=1
    done
}

#systemctl start libvirtd
case $action in
config)
    config_ib_sr_iov
    #kvm vm auto star
    # vm=vm${host_num}
    # virsh start $vm
    ;;
init)
    init_virtual_ib_devices
    ;;
*)
    echo "usage: need 1 param, init or config"
    ;;
esac
```

opensm服务运行节点需要在/etc/opensm/opensm.conf文件中添加`virt_enabled 2`



1. 宿主机上配置IB虚拟化

   - 在BIOS（或者UEFI setup）中已经启用了SR-IOV和vmx功能
   - 安装Infiniband的驱
   - 在grub启动参数中添加`intel_iommu=on iommu=pt`参数，重新生成grub.cfg
     1. add  intel_iommu=on iommu=pt  to /etc/default/grub CMDLINE
     2. generate grub.cfg
        - redhat uefi mode
          grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg  #centos is centos/grub.cfg
        - redhat bios (some distro uefi mode):
          grub2-mkconfig -o /boot/grub2/grub.cfg

2. 将虚拟出来的IB设备以直通方式到加入到虚拟机中

   向虚拟机中添加虚拟出来的PCI设备



3. 在虚拟机中安装Infiniband驱动

   

4. 宿主机开机自动配置虚拟IB卡信息

   *虚拟IB卡在宿主机重启后，部分配置信息会丢失。*

   在宿主机系统引导完成后执行以下内容，在宿主机启动后根据主机编号为虚拟的ib卡配置地址等信息，以确保IB虚拟化正常，且虚拟机在IB虚拟化完成后才启动，避免虚拟机启动后没有可用的IB。

   ```shell
   log=/tmp/ib-sriov-kvm.log
   echo "===$(date)===" > $log
   
   #主机编号 eg. c09 --> 09
   host_num=$(cat /etc/hostname | /usr/bin/grep -oE "[0-9]+") #eg. 09
   
   node_addr=11:11:11:11:11:11:${host_num}:00
   
   port_addr=11:11:11:11:11:11:${host_num}:01
   
   #虚拟出1个ib卡
   echo 1 > /sys/class/infiniband/mlx5_0/device/mlx5_num_vfs
   echo Follow > /sys/class/infiniband/mlx5_0/device/sriov/0/policy
   #为虚拟ib卡设置地址
   echo $node_addr > /sys/class/infiniband/mlx5_0/device/sriov/0/node
   echo $port_addr > /sys/class/infiniband/mlx5_0/device/sriov/0/port
   echo 0000:af:00.1 > /sys/bus/pci/drivers/mlx5_core/unbind
   echo 0000:af:00.1 > /sys/bus/pci/drivers/mlx5_core/bind
   
   sleep 10
   #启动虚拟机
   vm=vm${host_num}
   echo "start $vm ..." &>> $log
   virsh start $vm &>> $log
   ```

   

   可以用crontab的`@reboot`任务或`/etc/rc.local`或stemd unit方式实现自启动。

   如果要自启动虚拟机系统，确保虚拟机在以上命令执行后再启动。