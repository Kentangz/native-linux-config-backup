#!/system/bin/sh

UBUNTU_PATH="/data/linux-ubuntu"
LOG_FILE="/sdcard/CustomLog/Sda32/linux_boot.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

cleanup_on_fail() {
    log_msg "CRITICAL ERROR: Cleaning up mounts..."
    umount "$UBUNTU_PATH/sdcard" 2>/dev/null
    umount "$UBUNTU_PATH/dev/pts" 2>/dev/null
    umount "$UBUNTU_PATH/proc" 2>/dev/null
    umount "$UBUNTU_PATH/sys" 2>/dev/null
    umount "$UBUNTU_PATH/dev" 2>/dev/null
    umount -l "$UBUNTU_PATH" 2>/dev/null
}

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
    log_msg "Mounting partition sda32..."
    mount -t ext4 -o rw,noatime /dev/block/sda32 "$UBUNTU_PATH"
    
    if [ $? -ne 0 ]; then
        log_msg "ERROR: Cannot mount partition sda32"
        exit 1
    fi
    log_msg "Partition sda32 mounted successfully"
else
    log_msg "Partition sda32 already mounted. Skipping."
fi

# Mount virtual filesystems
log_msg "Mounting virtual filesystems..."

for dir in dev sys proc; do
    if ! grep -qs "$UBUNTU_PATH/$dir " /proc/mounts; then
        mount -o bind /$dir "$UBUNTU_PATH/$dir" || { 
            log_msg "ERROR: Failed to mount /$dir"; 
            cleanup_on_fail;
            exit 1; 
        }
        log_msg "/$dir mounted successfully"
    else
        log_msg "/$dir already mounted. Skipping."
    fi
done

# Mount devpts
if ! grep -qs "$UBUNTU_PATH/dev/pts " /proc/mounts; then
    mount -t devpts -o gid=5,mode=620 devpts "$UBUNTU_PATH/dev/pts" || { 
        log_msg "ERROR: Failed to mount devpts"; 
        cleanup_on_fail;
        exit 1; 
    }
    log_msg "devpts mounted successfully"
else
    log_msg "devpts already mounted. Skipping."
fi

# Mount SDCard
if [ ! -d "$UBUNTU_PATH/sdcard" ]; then 
    mkdir -p "$UBUNTU_PATH/sdcard"
fi

if ! grep -qs "$UBUNTU_PATH/sdcard " /proc/mounts; then
    mount -o bind /sdcard "$UBUNTU_PATH/sdcard"
    if [ $? -eq 0 ]; then
        log_msg "SDCard mounted successfully"
    else
        log_msg "WARNING: Failed to mount sdcard (non-fatal, continuing...)"
    fi
else
    log_msg "SDCard already mounted. Skipping."
fi

log_msg "All virtual filesystems ready"

# Prepare SSH
chroot "$UBUNTU_PATH" /usr/bin/env -i PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "mkdir -p /run/sshd && chmod 0755 /run/sshd"

# Start SSH daemon
log_msg "Starting SSH daemon..."

if pgrep -f "/usr/sbin/sshd" > /dev/null; then
    log_msg "WARNING: SSH daemon is ALREADY running. Skipping start."
else
    chroot "$UBUNTU_PATH" /usr/sbin/sshd
    sleep 2
    
    if pgrep -f "/usr/sbin/sshd" > /dev/null; then
        log_msg "SUCCESS: SSH daemon started successfully!"
    else
        log_msg "ERROR: sshd command executed but process died immediately."
        cleanup_on_fail
        exit 1
    fi
fi

log_msg "Boot process completed successfully"
