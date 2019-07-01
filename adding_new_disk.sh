###########################################
# Attach additional disk on linux OS
#
###########################################

How Linux Kernel deals with partition and file system
-----------------------------------------------------
1. Linux kernel detects local storage and remote storage devices
2. Linux kernel passes this information to "systemd-udev" process
3. 'systemd-dev' creates the device file in '/dev' directory
4. 'systemd-dev' also updates the '/sys' directory about the information of new storage device
5. 'systemd-dev' loads the file system modules if needed


Storage Devices Name
--------------------
1. SCSI block devices - /dev/sdX (/dev/sda)
2. Virtual block devices - /dev/vdX (/dev/vda)
3. Xen/HyperV block devices - /dev/xvdX (/dev/xvda)
4. DVD / CDROM - /dev/srY

Persistence Device Naming Standard
----------------------------------
4 different schemes for persistent naming
- label
- uuid
- id
- path

Linux Disk Partitioning
-----------------------
There are 2 partitioning schemes are available in linux MBR and GPT
1. In MBR, 4 primary partitions can be used due to limited amount of disk space that is reserved in master boot records to store partitions (64 bytes only)
  - To implement more than 4 partitions we can use 3 primary partition and 1 extended partition.
  - Extended partition can contain upto 12 logical partitions
2. GPT (Grid based Partition Table) is the default in modern disk and requires disk to be size of more than 2 TBs
  - In GPT 128 partitions can be created with no limit on primary / extended / logical partitions

Partition Utilities
-------------------
'fdisk' - universal partitioning utility, found on all unix distros
'gdisk' - only supports GPT layout
'parted' - can be used interactively (via shell) or non-interactively by providing all parameters, preferred in many distros
'gparted' - graphical interface for parted

Creating Parition
-----------------
# to view the newly attached disk
fdisk -l
lsblk
cat /proc/partitions


# as root, open fdisk by specifying disk.
sudo fdisk /dev/sdb

p - print the overview
n - add new partition to disk
1 - partition number (1-128 default 1)
enter - use defaults for starting sector to use the whole disk
+5000M - use defaults for ending sector to use the whole disk
p - view again
w - write the partition table to disk.


# list block again
lsblk

# format disk
# root space reservation on secondary disk isn't required, specify -m 0 to use all of the available disk space.
# By disabling lazy initialization and enabling DISCARD commands, you can get fast format and mount
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,discard /dev/[DEVICE_ID]
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,discard /dev/sdb1

# find the UUID of the disk
ls -l /dev/disk/by-uuid

blkid /dev/sdb1


# Create a directory that serves as the mount point for the new disk
sudo mkdir -p /mnt/disks/[MNT_DIR]
sudo mkdir -p /data

sudo chown user:user /data

# append the point entry in fstab file
# [NOFAIL_OPTION] is a variable that specifies what the operating system should do if it cannot mount the zonal persistent disk at boot time. To allow the system to continue booting even when it cannot mount the zonal persistent disk, specify this option. For most distributions, specify the nofail option. For Ubuntu 12.04 or Ubuntu 14.04, specify the nobootwait option.
sudo cp /etc/fstab /etc/fstab.backup

echo UUID=`sudo blkid -s UUID -o value /dev/sdb1` /data ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab


# very important | verify fstab entries
---------------------------------------
mount -fav

# mount file system
mount -a

# to view all mounts
mount


# to remount with ro / rw mode
mount -o remount <option> <mount-point>
mount -o remount rw /
mount -o remount ro /


# Delete partition with fdisk
-----------------------------
# list of current partition schemes
fdisk -l

# fdisk with desired partion to devic to delete
fdisk /dev/sdc
# now if there are more than one partition then count the partition number
# within fdisk type 'p' to print partition
'command (m for help)': p
'command (m for help)': d
'Partition number (1-4)': 2
# within fdisk type 'p' to print partition
'command (m for help)': p
# write the changes
'command (m for help)': w

###################################
# disk resize on Google Cloud
-----------------------------
# https://cloud.google.com/compute/docs/disks/add-persistent-disk

gcloud compute disks resize diskresize02 --size 20 --zone asia-south1-c

sudo df -h

sudo lsblk

# sudo growpart /dev/[DEVICE_ID] [PARTITION_NUMBER]
sudo growpart /dev/sda 1

# Extend the file system on the disk
sudo xfs_growfs /dev/sda1


# grow disk when it has occupied all 100% space
-----------------------------------------------
# So in Case anyone had the issue where they ran into this issue with 100% use , and no space to even run growpart command (because it creates a file in /tmp)

# Here is a command that i found that bypasses even while the EBS volume is being used , and also if you have no space left on your ec2 , and you are at 100%

/sbin/parted ---pretend-input-tty /dev/xvda resizepart 1 yes 100%

# This command should be followed by
sudo resize2fs /dev/xvda1
# to update /etc/fstab, only after that df -h will show the grown disk space

https://www.elastic.co/blog/autoresize-ebs-root-volume-on-aws-amis
