# native-linux-config-backup

.env :
 - Android 16
 - Kernel Linux version 4.14.356
 - Unlock Bootloader
 - [Magisk](https://github.com/topjohnwu/magisk/releases)
 - [BusyBox](https://github.com/Magisk-Modules-Alt-Repo/BuiltIn-BusyBox/releases)
 - [Termux](https://github.com/termux/termux-app)
 - Disk Partition
 
  **Format Partition**

     /system/bin/mke2fs -t ext4 /dev/block/sda32`

   
**Permission & Mounting**

    mkdir -p /data/linux-ubuntu
    chmod 700 /data/linux-ubuntu
    mount -t ext4 /dev/block/sda32 /data/linux-ubuntu
    df -h /data/linux-ubuntu


**Download & Extract Ubuntu Base 24.04.3 arm64**

    curl -L -o ubuntu-rootfs.tar.gz
    https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-arm64.tar.gz
    tar xpvf ubuntu-rootfs.tar.gz --numeric-owner
    rm ubuntu-rootfs.tar.gz
    ls -F

**DNS**

    echo "nameserver 8.8.8.8" > /data/linux-ubuntu/etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /data/linux-ubuntu/etc/resolv.conf
    echo "127.0.0.1 localhost" > /data/linux-ubuntu/etc/hosts


**Script Enter & Exit Ubuntu**

    nano /data/start_ubuntu.sh
```bash
#!/system/bin/sh

UBUNTU_PATH="/data/linux-ubuntu"

# Bind Mount
mount --bind /dev $UBUNTU_PATH/dev
mount --bind /sys $UBUNTU_PATH/sys
mount --bind /proc $UBUNTU_PATH/proc
mount -t devpts devpts $UBUNTU_PATH/dev/pts

# Mount Internal Storage
if [ ! -d "$UBUNTU_PATH/sdcard" ]; then
    mkdir -p $UBUNTU_PATH/sdcard
fi
mount --bind /sdcard $UBUNTU_PATH/sdcard

# Enter Ubuntu
echo "Enter Ubuntu..."
chroot $UBUNTU_PATH /bin/su - root

# Unmount when exit
echo "Clear mount point..."
umount $UBUNTU_PATH/dev/pts
umount $UBUNTU_PATH/dev
umount $UBUNTU_PATH/sys
umount $UBUNTU_PATH/proc
umount $UBUNTU_PATH/sdcard
echo "Done"
```
    sh /data/start_ubuntu.sh
