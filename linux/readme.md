# Linux Command Reference Guide
This comprehensive documentation covers essential Linux system commands categorized by function.

### 📂 File & Directory Management
* **List contents detailed**: `ls -lah`
* **Change current directory**: `cd /path/to/folder`
* **Print working directory**: `pwd`
* **Create empty directory**: `mkdir -p new_folder`
* **Create blank file**: `touch file.txt`
* **Copy files recursively**: `cp -r source/ dest/`
* **Move or rename file**: `mv old.txt new.txt`
* **Remove file permanently**: `rm file.txt`
* **Force remove directory**: `rm -rf folder/`
* **Check file type**: `file document.pdf`
* **Symbolic link creation**: `ln -s target_file link_name`

### 🔍 Search & Text Processing
* **Search text pattern**: `grep -rnI "search_term" .`
* **Find files by name**: `find . -name "*.log"`
* **Locate binary path**: `which nginx`
* **View file from top**: `head -n 20 file.txt`
* **Output trailing stream**: `tail -f /var/log/syslog`
* **View complete file**: `cat file.txt`
* **Interactive text reader**: `less file.txt`
* **Count lines or words**: `wc -l file.txt`
* **Stream editor replace**: `sed -i 's/old/new/g' file.txt`
* **Text pattern processor**: `awk '{print $1}' file.txt`

### ⚙️ System Information & Resources
* **Display human disk space**: `df -h`
* **Directory space utilization**: `du -sh *`
* **Check memory stats**: `free -h`
* **Interactive process manager**: `htop`
* **Standard process snapshot**: `ps aux`
* **Kill process by ID**: `kill -9 PID`
* **Kill process by name**: `killall nginx`
* **Show system architecture**: `uname -a`
* **Display system uptime**: `uptime`
* **View kernel boot messages**: `dmesg -T`

### 🔒 Permissions & Users
* **Modify file permissions**: `chmod 755 script.sh`
* **Change owner and group**: `chown user:group file.txt`
* **Execute command as root**: `sudo command`
* **Switch login identity**: `su - username`
* **Show active current user**: `whoami`
* **Add new system user**: `sudo adduser username`
* **Delete system user**: `sudo deluser username`
* **Modify user groups**: `sudo usermod -aG groupname user`

### 🌐 Networking & Connectivity
* **Test host reachability**: `ping -c 4 8.8.8.8`
* **Display network sockets**: `ss -tulnp`
* **Show interface addresses**: `ip a`
* **Trace network packets**: `traceroute google.com`
* **Test network port link**: `nc -zv host 80`
* **Query DNS records**: `dig domain.com`
* **Download web resource**: `curl -O http://example.com`
* **Alternative mirror fetch**: `wget http://example.com`

### 📦 Archiving & Package Management
* **Create compressed tar**: `tar -czvf archive.tar.gz folder/`
* **Extract tar archive**: `tar -xzvf archive.tar.gz`
* **Unzip standard archive**: `unzip archive.zip`
* **Update package indexes**: `sudo apt update`
* **Upgrade system binaries**: `sudo apt upgrade -y`
* **Install explicit package**: `sudo apt install package_name`
* **Purge target package**: `sudo apt remove --purge package_name`
---
---

# Linux Architecture & Commands — Detailed Reference

## 1. High-Level Architecture

Linux follows a **layered, monolithic-kernel architecture**. User applications never touch hardware directly — they go through the kernel via system calls.

```
┌───────────────────────────────────────────────────────────────────┐
│                          USER SPACE                                 │
│                                                                       │
│   ┌───────────────┐  ┌───────────────┐  ┌────────────────────┐     │
│   │  Applications  │  │  Shells (bash,│  │  System Utilities  │     │
│   │ (Firefox, vim, │  │  zsh, fish)   │  │  (ls, cp, systemd, │     │
│   │  python, etc.) │  │               │  │   cron, etc.)       │     │
│   └───────┬───────┘  └───────┬───────┘  └──────────┬─────────┘     │
│           │                  │                       │              │
│   ┌───────▼──────────────────▼───────────────────────▼─────────┐   │
│   │                    C Standard Library (glibc)                │   │
│   │           (wraps syscalls: malloc, printf, open, fork)       │   │
│   └───────────────────────────┬────────────────────────────────┘   │
└───────────────────────────────┼──────────────────────────────────── ┘
                                 │  System Call Interface (SCI)
┌───────────────────────────────▼──────────────────────────────────── ┐
│                          KERNEL SPACE                                │
│                                                                       │
│  ┌────────────┐ ┌──────────────┐ ┌─────────────┐ ┌───────────────┐  │
│  │  Process    │ │   Memory      │ │  Filesystem  │ │   Network     │  │
│  │  Scheduler  │ │   Manager     │ │   (VFS)      │ │   Stack       │  │
│  │  (CFS/EEVDF)│ │   (MMU, paging│ │  ext4, xfs,  │ │  TCP/IP,      │  │
│  │             │ │   swap)       │ │  btrfs, etc. │ │  netfilter    │  │
│  └────────────┘ └──────────────┘ └─────────────┘ └───────────────┘  │
│                                                                       │
│  ┌──────────────────────────┐   ┌─────────────────────────────────┐│
│  │  Device Drivers           │   │  IPC / Namespaces / cgroups     ││
│  │  (block, char, network)   │   │  (isolation & resource control) ││
│  └──────────────────────────┘   └─────────────────────────────────┘│
└───────────────────────────────┬──────────────────────────────────── ┘
                                 │
┌───────────────────────────────▼──────────────────────────────────── ┐
│                            HARDWARE                                  │
│        CPU  │  RAM  │  Disk/SSD  │  NIC  │  GPU  │  Peripherals      │
└───────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Kernel Subsystems

### 2.1 Process Scheduler
- Decides which process/thread runs on which CPU core, and for how long.
- Modern kernels (5.x+) primarily used **CFS (Completely Fair Scheduler)**; kernel 6.6+ introduced **EEVDF (Earliest Eligible Virtual Deadline First)** as the default.
- Handles priorities (`nice` values -20 to 19), real-time scheduling classes (`SCHED_FIFO`, `SCHED_RR`), and multi-core load balancing.

### 2.2 Memory Manager
- Manages **virtual memory**: each process gets its own address space mapped to physical RAM via the **MMU (Memory Management Unit)**.
- Handles **paging**, **swapping**, **demand paging** (pages loaded only when accessed), and the **page cache** (caches file data in RAM).
- The **OOM killer** terminates processes when the system runs critically low on memory.

### 2.3 Virtual File System (VFS)
- An abstraction layer that lets Linux support many filesystem types (`ext4`, `xfs`, `btrfs`, `nfs`, `tmpfs`, etc.) through one unified interface.
- Everything is a file in Linux — devices, sockets, and pipes are all accessed through the VFS.

### 2.4 Network Stack
- Implements the full TCP/IP stack in-kernel.
- **netfilter** provides the hook framework used by `iptables`/`nftables` for firewalling, NAT, packet mangling.

### 2.5 Device Drivers
- **Block devices** — disks, SSDs (buffered, addressable in blocks).
- **Character devices** — keyboards, serial ports (streamed, byte-by-byte).
- **Network devices** — NICs.
- Drivers can be built into the kernel or loaded dynamically as **kernel modules** (`.ko` files).

### 2.6 IPC, Namespaces & cgroups
- **IPC** — pipes, message queues, shared memory, semaphores, sockets for inter-process communication.
- **Namespaces** — isolate what a process can see (pid, net, mnt, uts, ipc, user, cgroup).
- **cgroups** — limit/measure resource usage (CPU, memory, I/O) per process group. These two are the foundation containers (Docker, LXC) are built on.

---

## 3. Boot Process

```
Power On
   │
   ▼
1. BIOS/UEFI  ──► POST (hardware self-test), locates boot device
   │
   ▼
2. Bootloader (GRUB2 / systemd-boot) ──► loads kernel image + initramfs
   │
   ▼
3. Kernel Initialization ──► sets up memory, scheduler, drivers
   │
   ▼
4. initramfs ──► temporary root FS, loads drivers needed to mount real root
   │
   ▼
5. Switch root ──► pivots to actual root filesystem
   │
   ▼
6. init system (systemd / init / OpenRC) ──► PID 1, starts services
   │
   ▼
7. Target/Runlevel reached ──► login prompt / GUI
```

---

## 4. Filesystem Hierarchy Standard (FHS)

| Path | Purpose |
|---|---|
| `/` | Root of the filesystem |
| `/bin`, `/usr/bin` | Essential/user executables |
| `/sbin`, `/usr/sbin` | System admin binaries |
| `/etc` | System-wide configuration files |
| `/home` | User home directories |
| `/root` | Root user's home directory |
| `/var` | Variable data: logs, mail, spool, caches |
| `/tmp` | Temporary files, cleared on reboot |
| `/usr` | User-installed software, libraries, docs |
| `/lib`, `/usr/lib` | Shared libraries |
| `/opt` | Optional/third-party software |
| `/proc` | Virtual FS exposing kernel/process info |
| `/sys` | Virtual FS exposing kernel/device info |
| `/dev` | Device files |
| `/mnt`, `/media` | Mount points for external/removable filesystems |
| `/boot` | Kernel image, bootloader files |

---

## 5. Process & Memory Model

```
              fork()                exec()
Process A ───────────► Process B ───────────► New Program
(parent)                (child, copy)          (replaces child's memory)

Process states:
  R (Running)  →  S (Sleeping) → D (Uninterruptible sleep)
       ↑                                │
       └──────── Z (Zombie) ◄───────────┘ (after exit, before reaped)
                     │
                     ▼
              T (Stopped, e.g. via SIGSTOP)
```

- Every process has a **PID**, a **PPID** (parent), and belongs to a **process group** / **session**.
- `fork()` creates a near-identical copy of a process; `exec()` replaces a process's memory image with a new program.
- **PID 1** (`systemd` or `init`) is the ancestor of all other processes and reaps orphaned zombies.

---

## 6. Essential Commands by Category

### 6.1 File & Directory Management
```bash
ls -la              # list files, including hidden, long format
cd /path/to/dir     # change directory
pwd                 # print working directory
cp -r src/ dest/    # copy recursively
mv old new          # move/rename
rm -rf dir/         # remove recursively, force
mkdir -p a/b/c      # create nested directories
rmdir dir           # remove empty directory
find . -name "*.log" # search files by pattern
locate filename     # fast search using prebuilt index
tree                # show directory structure as a tree
ln -s target link   # create symbolic link
touch file.txt      # create empty file / update timestamp
stat file.txt       # detailed file metadata
```

### 6.2 File Viewing & Editing
```bash
cat file.txt          # print whole file
less file.txt          # paginated view
head -n 20 file.txt    # first 20 lines
tail -f /var/log/syslog # follow log in real time
grep -rn "pattern" .   # recursive search with line numbers
sed 's/foo/bar/g' f    # stream editor (find & replace)
awk '{print $1}' f     # pattern-based text processing
diff file1 file2       # compare files
vim / nano file.txt    # text editors
```

### 6.3 Permissions & Ownership
```bash
chmod 755 file.sh       # rwxr-xr-x
chmod u+x script.sh     # add execute for owner
chown user:group file   # change ownership
chgrp group file        # change group
umask                   # show default permission mask
sudo command             # run as superuser
su - username            # switch user
id                        # show current UID/GID/groups
```

Permission bits: `r=4, w=2, x=1` per owner/group/other (e.g. `755` = `rwxr-xr-x`).

### 6.4 Process Management
```bash
ps aux                  # list all running processes
ps -ef --forest          # process tree view
top / htop                # live resource usage
kill -9 PID               # force kill a process
killall processname       # kill by name
pkill -f pattern          # kill matching pattern
nice -n 10 command         # start with lower priority
renice -n 5 -p PID         # change priority of running process
jobs                        # list background jobs
bg / fg                     # resume job in background/foreground
nohup command &              # run immune to hangups
systemctl status service     # check systemd service status
systemctl start/stop/restart service
journalctl -u service -f     # follow logs for a systemd unit
```

### 6.5 Disk & Filesystem
```bash
df -h                   # disk space usage (human-readable)
du -sh dir/              # size of a directory
mount /dev/sdb1 /mnt      # mount a device
umount /mnt                # unmount
lsblk                       # list block devices
fdisk -l                    # list partitions
mkfs.ext4 /dev/sdb1          # format a partition
fsck /dev/sdb1                # check/repair filesystem
```

### 6.6 Networking
```bash
ip addr show              # show IP addresses (modern)
ifconfig                    # legacy interface config
ip route                     # show routing table
ping host                      # test connectivity
curl -I https://example.com     # fetch headers
wget URL                          # download a file
ss -tulnp                          # show listening ports (modern netstat)
netstat -tulnp                      # legacy version
dig domain.com / nslookup domain    # DNS lookup
scp file user@host:/path             # secure copy over SSH
ssh user@host                          # remote shell
rsync -avz src/ user@host:dest/         # efficient file sync
iptables -L / nft list ruleset            # firewall rules
```

### 6.7 Users & Groups
```bash
useradd -m username        # create user with home dir
usermod -aG group user      # add user to group
userdel -r username           # delete user + home dir
groupadd groupname             # create group
passwd username                  # change password
whoami                              # current user
who / w                               # logged-in users
```

### 6.8 Package Management
```bash
# Debian/Ubuntu (APT)
apt update && apt upgrade
apt install package
apt remove package

# RHEL/Fedora/CentOS (DNF/YUM)
dnf install package
dnf update

# Arch
pacman -S package

# Universal / language-agnostic
snap install package
flatpak install package
```

### 6.9 Compression & Archiving
```bash
tar -czvf archive.tar.gz dir/    # create gzip tarball
tar -xzvf archive.tar.gz          # extract gzip tarball
zip -r archive.zip dir/             # zip a directory
unzip archive.zip                    # extract zip
gzip file / gunzip file.gz            # gzip compress/decompress
```

### 6.10 System Monitoring & Info
```bash
uname -a               # kernel/system info
uptime                   # load average, uptime
free -h                    # memory usage
vmstat 1                     # virtual memory stats, refresh every 1s
iostat                         # disk I/O stats
lscpu                             # CPU architecture info
dmesg | tail                        # kernel ring buffer messages
who -b                                 # last boot time
history                                   # command history
env / printenv                              # environment variables
export VAR=value                              # set environment variable
```

### 6.11 Text/Data Processing Pipeline Example
```bash
# Find top 5 IPs hitting the server from an access log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5
```

### 6.12 Scheduling
```bash
crontab -e                  # edit current user's cron jobs
crontab -l                    # list cron jobs
at 5pm                           # schedule a one-time job
systemd-run --on-calendar=...     # systemd timer equivalent
```

---

## 7. Init Systems Compared

| System | Notes |
|---|---|
| `systemd` | Default on most modern distros (Ubuntu, Fedora, RHEL, Debian, Arch). Uses unit files, parallel startup, `journalctl` for logging. |
| `SysVinit` | Legacy, sequential shell-script-based startup (`/etc/init.d/`). |
| `OpenRC` | Used by Gentoo, Alpine; lighter than systemd. |
| `runit` | Minimal, used by Void Linux and some container base images. |

---

## 8. Permissions & Security Model

- **DAC (Discretionary Access Control)** — traditional owner/group/other + rwx permissions.
- **MAC (Mandatory Access Control)** — `SELinux` (RHEL/Fedora) or `AppArmor` (Ubuntu/Debian) enforce policy-based restrictions beyond DAC.
- **Capabilities** — fine-grained root privilege splitting (`CAP_NET_BIND_SERVICE`, `CAP_SYS_ADMIN`, etc.) instead of all-or-nothing root.
- **SUID/SGID/Sticky bit** — special permission bits (`chmod +s`, `chmod +t`) controlling execution privilege and directory deletion rules.

---

## 9. Summary: Full Stack View

```
 User Applications / Shells
          │
   glibc (syscall wrappers)
          │
   System Call Interface
          │
 ┌────────┴─────────────────────────────┐
 │   Linux Kernel                         │
 │   Scheduler │ Memory │ VFS │ Net Stack │
 │   Drivers │ Namespaces │ cgroups       │
 └────────┬─────────────────────────────┘
          │
      Hardware (CPU, RAM, Disk, NIC)
```
