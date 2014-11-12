#!/bin/bash
BLOCK='root@192.168.1.1'
scp $BLOCK:/etc/vtrunkd.conf ./
scp $BLOCK:/etc/dropbear/authorized_keys ./
scp $BLOCK:/etc/modems.conf ./
sudo mount ./bin/sunxi/openwrt-sunxi-root.ext4 /mnt -t ext4 -o loop=/dev/loop0
sudo mv ./authorized_keys /mnt/etc/dropbear/
sudo mv ./vtrunkd.conf /mnt/etc/
sudo mv ./modems.conf /mnt/etc/
sudo sync
sudo umount /mnt
e2fsck -f ./bin/sunxi/openwrt-sunxi-root.ext4
resize2fs ./bin/sunxi/openwrt-sunxi-root.ext4 240M
scp ./bin/sunxi/openwrt-sunxi-root.ext4 $BLOCK:/tmp/fs.bin
ssh $BLOCK cp /bin/sync /tmp/
ssh $BLOCK cp /sbin/reboot /tmp/
ssh $BLOCK dd if=/tmp/fs.bin of=/dev/mmcblk0p2 bs=128k
ssh $BLOCK /tmp/sync
ssh $BLOCK /tmp/reboot
