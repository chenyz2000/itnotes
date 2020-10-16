As of MLNX_OFED v4.7, the NFSoRDMA driver is no longer installed by default. In order to install it over a supported kernel, add the “ --with-nfsrdma ” installation option to the “mlnxofedinstall” script.


-----


mlnx-nfsrdma-dkms

nfs 

Deep buried in MLNX_OFED 4 release notes is a laconic remark that support for NFS over RDMA has been removed. No rationale is provided, and seemingly no one knows why this useful feature was omitted. Fortunately, the release notes turn out to be inaccurate on this point, and the NFS/RDMA support is in fact included in MLNX_OFED, but is not installed by default.


The package that must be installed in addition to the standard MLNX_OFED install is mlnx-nfsrdma-dkms. The procedure below is for Ubuntu 16.04 with kernel 4.13. As of this writing this is the HWE kernel; Ubuntu ISOs are currently distributed with kernel 4.10, which is updated to 4.13 by full upgrade. I tested kernel 4.4 and found that it is not compatible with mlnx-nfsrdma-dkms, so if you have an install with kernel 4.4, you need to replace it with the HWE kernel.

------


The solution was to remove MLNX_OFED and use the distribution's drivers/kernel modules.

---
NFSoRDMA is not supported in the Mellanox OFED version 3.4 and higher. However, inbox OS driver can be used if NFSoRDMA support is necessary.