#!/system/bin/sh

UBUNTU_PATH="/data/linux-ubuntu"
LOG_FILE="/sdcard/CustomLog/Sda32/linux_boot.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

cleanup() {
    log_msg "Cleaning up mounts..."
    umount "$UBUNTU_PATH/sdcard" 2>/dev/null
    umount "$UBUNTU_PATH/dev/pts" 2>/dev/null
    umount "$UBUNTU_PATH/proc" 2>/dev/null
    umount "$UBUNTU_PATH/sys" 2>/dev/null
    umount "$UBUNTU_PATH/dev" 2>/dev/null
}

trap cleanup EXIT

log_msg "Starting boot process..."
sleep 20

# Create Ubuntu directory
if [ ! -d "$UBUNTU_PATH" ]; then
    mkdir -p "$UBUNTU_PATH"
    chmod 755 "$UBUNTU_PATH"
    log_msg "Created Ubuntu directory"
fi

# Mount main partition
if ! grep -qs "$UBUNTU_PATH " /proc/mounts; then
    log_msg "Mounting partition..."
    if mount -t ext4 -o rw,noatime /dev/block/sda32 "$UBUNTU_PATH"; then
        log_msg "Partition mounted successfully"
    else
        log_msg "ERROR: Cannot mount partition"
        exit 1
    fi
else
    log_msg "Partition already mounted"
fi

# Mount virtual filesystems
log_msg "Mounting virtual filesystems..."
mount -o bind /dev "$UBUNTU_PATH/dev" || { log_msg "ERROR: Failed to mount /dev"; exit 1; }
mount -o bind /sys "$UBUNTU_PATH/sys" || { log_msg "ERROR: Failed to mount /sys"; exit 1; }
mount -o bind /proc "$UBUNTU_PATH/proc" || { log_msg "ERROR: Failed to mount /proc"; exit 1; }
mount -t devpts -o gid=5,mode=620 devpts "$UBUNTU_PATH/dev/pts" || { log_msg "ERROR: Failed to mount devpts"; exit 1; }

# Mount SDCard
mkdir -p "$UBUNTU_PATH/sdcard"
mount -o bind /sdcard "$UBUNTU_PATH/sdcard" || { log_msg "ERROR: Failed to mount sdcard"; exit 1; }

log_msg "Virtual filesystems mounted successfully"

# Prepare SSH
chroot "$UBUNTU_PATH" /usr/bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "mkdir -p /run/sshd && chmod 0755 /run/sshd"

# Start SSH daemon
log_msg "Starting SSH daemon..."
if chroot "$UBUNTU_PATH" /usr/sbin/sshd; then
    sleep 2
    if pgrep -x "sshd" > /dev/null; then
        log_msg "SSH daemon started successfully"
    else
        log_msg "WARNING: sshd command succeeded but process not found"
    fi
else
    log_msg "ERROR: Failed to start SSH daemon"
    exit 1
fi

log_msg "Boot process completed"
