#!/bin/bash

#dd if=sunxi/uboot-sunxi-Cubietruck/openwrt-sunxi-Cubietruck-u-boot-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8
dd if=sunxi/uboot-sunxi-Cubieboard2/openwrt-sunxi-Cubieboard2-u-boot-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8
mkfs.vfat /dev/mmcblk0p1
mount -t vfat /dev/mmcblk0p1 /mnt/
#cp sunxi/uboot-sunxi-Cubietruck/openwrt-sunxi-Cubietruck-uEnv.txt /mnt/uEnv.txt
cp sunxi/uboot-sunxi-Cubieboard2/openwrt-sunxi-Cubieboard2-uEnv.txt /mnt/uEnv.txt
cp sunxi/sun7i-a20-cubieboard2.dtb  /mnt/dtb
cp sunxi/openwrt-sunxi-uImage /mnt/uImage
resize2fs sunxi/openwrt-sunxi-root.ext4 240M
dd if=sunxi/openwrt-sunxi-root.ext4 of=/dev/mmcblk0p2 bs=128k
sync
umount /mnt
