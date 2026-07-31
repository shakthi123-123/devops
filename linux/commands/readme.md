# Linux Commands — Complete Reference Guide

A comprehensive, categorized reference of essential Linux commands with syntax, common flags, and practical examples — covering file management, permissions, processes, networking, package management, disk/storage, users, text processing, and system administration.

---

## Table of Contents

1. [File & Directory Management]()
2. File Permissions & Ownership
3. Viewing & Editing Files
4. Text Processing & Searching
5. Process Management
6. System Information & Monitoring
7. Networking
8. Package Management
9. Disk & Storage Management
10. User & Group Management
11. Archiving & Compression
12. SSH & Remote Access
13. Scheduling & Automation
14. System Logs
15. Shell Scripting Essentials
16. Environment Variables
17. Useful Command Combinations

---

## 1. File & Directory Management

| Command | Description | Example |
|---|---|---|
| `pwd` | Print working directory | `pwd` |
| `ls` | List directory contents | `ls -la` (long format, show hidden) |
| `cd` | Change directory | `cd /var/log` / `cd ..` / `cd ~` |
| `mkdir` | Create a directory | `mkdir -p project/src/utils` (`-p` creates parents) |
| `rmdir` | Remove an empty directory | `rmdir old_folder` |
| `rm` | Remove files/directories | `rm file.txt` / `rm -rf folder/` (force, recursive) |
| `cp` | Copy files/directories | `cp file.txt backup.txt` / `cp -r src/ dest/` |
| `mv` | Move or rename | `mv old.txt new.txt` / `mv file.txt /tmp/` |
| `touch` | Create empty file / update timestamp | `touch newfile.txt` |
| `find` | Search for files | `find /home -name "*.log"` |
| `locate` | Fast file search (uses index) | `locate nginx.conf` |
| `which` | Show path of a command | `which python3` |
| `file` | Determine file type | `file document.pdf` |
| `tree` | Display directory structure as a tree | `tree -L 2` (2 levels deep) |
| `ln` | Create links | `ln -s /path/target link_name` (symbolic link) |
| `basename` | Strip directory from a path | `basename /home/user/file.txt` → `file.txt` |
| `dirname` | Strip filename, show directory | `dirname /home/user/file.txt` → `/home/user` |
| `readlink` | Resolve symlink target | `readlink -f symlink.txt` |

### `ls` Common Flags

| Flag | Meaning |
|---|---|
| `-l` | Long listing format (permissions, owner, size, date) |
| `-a` | Show hidden files (starting with `.`) |
| `-h` | Human-readable sizes (KB, MB, GB) |
| `-t` | Sort by modification time (newest first) |
| `-S` | Sort by file size (largest first) |
| `-R` | Recursive listing |
| `-1` | One file per line |

### `find` Common Examples

```bash
find . -name "*.py"                          # find by name pattern
find / -type f -size +100M                   # files larger than 100MB
find . -type d -empty                        # empty directories
find . -mtime -7                              # modified in last 7 days
find . -name "*.tmp" -delete                  # find and delete
find . -name "*.log" -exec gzip {} \;         # find and run a command on each
find / -perm -4000 2>/dev/null                # find SUID files
```

---

## 2. File Permissions & Ownership

| Command | Description | Example |
|---|---|---|
| `chmod` | Change file permissions | `chmod 755 script.sh` / `chmod u+x script.sh` |
| `chown` | Change file owner/group | `chown user:group file.txt` |
| `chgrp` | Change group ownership | `chgrp developers project/` |
| `umask` | Set default permission mask | `umask 022` |
| `stat` | Display detailed file metadata | `stat file.txt` |

### Permission Notation

```
-rwxr-xr-- 1 user group 4096 Jul 31 10:00 script.sh
 │└┬┘└┬┘└┬┘
 │ │  │  └── others: r-- (read only)
 │ │  └───── group: r-x (read, execute)
 │ └──────── owner: rwx (read, write, execute)
 └────────── file type (- = file, d = directory, l = symlink)
```

### Numeric (Octal) Permissions

| Value | Permission |
|---|---|
| `4` | Read (r) |
| `2` | Write (w) |
| `1` | Execute (x) |
| `7` | rwx (4+2+1) |
| `6` | rw- (4+2) |
| `5` | r-x (4+1) |

```bash
chmod 755 file    # rwxr-xr-x — owner: full, group/others: read+execute
chmod 644 file    # rw-r--r-- — owner: read+write, group/others: read only
chmod 700 file    # rwx------ — owner only
chmod -R 755 dir/ # recursive
```

### Symbolic Permission Changes

```bash
chmod u+x file      # add execute for owner (user)
chmod g-w file       # remove write for group
chmod o=r file        # set others to read-only
chmod a+r file         # add read for all (user, group, other)
```

---

## 3. Viewing & Editing Files

| Command | Description | Example |
|---|---|---|
| `cat` | Print entire file contents | `cat file.txt` |
| `tac` | Print file in reverse (last line first) | `tac file.txt` |
| `less` | View file page-by-page (searchable, scrollable) | `less large_file.log` |
| `more` | Similar to less, simpler | `more file.txt` |
| `head` | Show first N lines (default 10) | `head -n 20 file.txt` |
| `tail` | Show last N lines (default 10) | `tail -n 50 file.txt` |
| `tail -f` | Follow file in real time (live logs) | `tail -f /var/log/syslog` |
| `nl` | Print file with line numbers | `nl file.txt` |
| `nano` | Simple terminal text editor | `nano config.yaml` |
| `vim` / `vi` | Advanced modal text editor | `vim script.sh` |
| `wc` | Count lines/words/characters | `wc -l file.txt` (line count) |
| `diff` | Compare two files | `diff file1.txt file2.txt` |
| `cmp` | Byte-by-byte file comparison | `cmp file1.bin file2.bin` |

### `less` Navigation Cheatsheet

| Key | Action |
|---|---|
| `Space` / `f` | Next page |
| `b` | Previous page |
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` / `N` | Next / previous match |
| `g` / `G` | Go to start / end of file |
| `q` | Quit |

### Basic Vim Commands (Since It's Ubiquitous on Servers)

| Command | Action |
|---|---|
| `i` | Enter insert mode |
| `Esc` | Return to normal mode |
| `:w` | Save |
| `:q` | Quit |
| `:wq` or `ZZ` | Save and quit |
| `:q!` | Quit without saving |
| `dd` | Delete current line |
| `yy` | Copy (yank) current line |
| `p` | Paste |
| `/pattern` | Search |
| `:%s/old/new/g` | Replace all occurrences in file |

---

## 4. Text Processing & Searching

| Command | Description | Example |
|---|---|---|
| `grep` | Search text using patterns | `grep -i "error" logfile.txt` |
| `egrep` / `grep -E` | Extended regex grep | `grep -E "error|warning" log.txt` |
| `sed` | Stream editor — find/replace, transform text | `sed 's/old/new/g' file.txt` |
| `awk` | Pattern scanning and processing (columns) | `awk '{print $1}' file.txt` |
| `cut` | Extract columns/fields | `cut -d',' -f1,3 data.csv` |
| `sort` | Sort lines of text | `sort -n numbers.txt` |
| `uniq` | Remove/report duplicate lines | `sort file.txt \| uniq -c` |
| `tr` | Translate/delete characters | `tr 'a-z' 'A-Z' < file.txt` |
| `xargs` | Build commands from input | `find . -name "*.log" \| xargs rm` |
| `column` | Format text into aligned columns | `column -t -s',' data.csv` |

### `grep` Common Flags

| Flag | Meaning |
|---|---|
| `-i` | Case-insensitive |
| `-v` | Invert match (show non-matching lines) |
| `-r` / `-R` | Recursive search through directories |
| `-n` | Show line numbers |
| `-c` | Count matching lines |
| `-l` | List only filenames with matches |
| `-w` | Match whole words only |
| `-A n` / `-B n` | Show n lines after/before the match |

```bash
grep -rn "TODO" ./src              # recursive, with line numbers
grep -c "ERROR" app.log            # count error lines
grep -v "^#" config.conf           # exclude comment lines
grep -A 3 -B 1 "Exception" app.log # 1 line before, 3 lines after
```

### `sed` Common Examples

```bash
sed 's/foo/bar/' file.txt              # replace first occurrence per line
sed 's/foo/bar/g' file.txt             # replace all occurrences
sed -i 's/foo/bar/g' file.txt          # edit the file in place
sed -n '5,10p' file.txt                # print only lines 5-10
sed '/^$/d' file.txt                   # delete blank lines
```

### `awk` Common Examples

```bash
awk '{print $1}' file.txt                        # print first column
awk -F',' '{print $2}' data.csv                   # custom delimiter
awk '{sum += $3} END {print sum}' data.txt         # sum a column
awk '$3 > 100 {print $0}' data.txt                  # filter rows by condition
awk 'NR==5' file.txt                                 # print only line 5
```

---

## 5. Process Management

| Command | Description | Example |
|---|---|---|
| `ps` | Show running processes | `ps aux` |
| `top` | Real-time process monitor | `top` |
| `htop` | Enhanced interactive process viewer | `htop` |
| `kill` | Terminate a process by PID | `kill -9 1234` |
| `killall` | Terminate processes by name | `killall firefox` |
| `pkill` | Kill processes matching a pattern | `pkill -f "node server.js"` |
| `pgrep` | Find PIDs matching a pattern | `pgrep -f nginx` |
| `jobs` | List background jobs in current shell | `jobs` |
| `bg` | Resume a job in background | `bg %1` |
| `fg` | Bring a job to foreground | `fg %1` |
| `nohup` | Run a command immune to hangups | `nohup ./script.sh &` |
| `nice` | Run a process with adjusted priority | `nice -n 10 ./heavy_script.sh` |
| `renice` | Change priority of a running process | `renice 5 -p 1234` |
| `disown` | Detach a job from the shell | `disown %1` |

### `ps aux` Column Reference

| Column | Meaning |
|---|---|
| `USER` | Process owner |
| `PID` | Process ID |
| `%CPU` | CPU usage |
| `%MEM` | Memory usage |
| `VSZ` / `RSS` | Virtual / resident memory size |
| `STAT` | Process state (R=running, S=sleeping, Z=zombie) |
| `COMMAND` | The command that started the process |

### Common Signals

| Signal | Number | Purpose |
|---|---|---|
| `SIGHUP` | 1 | Hangup (often reload config) |
| `SIGINT` | 2 | Interrupt (Ctrl+C) |
| `SIGKILL` | 9 | Force kill (cannot be caught/ignored) |
| `SIGTERM` | 15 | Graceful termination request (default) |
| `SIGSTOP` | 19 | Pause process |

```bash
ps aux | grep nginx                # find a specific process
kill -15 1234                      # graceful shutdown (default)
kill -9 1234                       # force kill
pkill -9 -f "python app.py"        # kill by matched command
```

---

## 6. System Information & Monitoring

| Command | Description | Example |
|---|---|---|
| `uname -a` | Kernel and system info | `uname -a` |
| `hostname` | Show/set system hostname | `hostname` |
| `uptime` | System uptime and load average | `uptime` |
| `free -h` | Memory usage (human-readable) | `free -h` |
| `df -h` | Disk space usage per filesystem | `df -h` |
| `du -sh` | Disk usage of a directory | `du -sh /var/log` |
| `vmstat` | Virtual memory statistics | `vmstat 2 5` (every 2s, 5 times) |
| `iostat` | CPU and disk I/O statistics | `iostat -x 2` |
| `lscpu` | CPU architecture details | `lscpu` |
| `lsblk` | List block devices | `lsblk` |
| `lsusb` | List USB devices | `lsusb` |
| `lspci` | List PCI devices | `lspci` |
| `dmesg` | Kernel ring buffer messages | `dmesg \| tail -50` |
| `who` | Show logged-in users | `who` |
| `w` | Show logged-in users + activity | `w` |
| `last` | Show login history | `last -10` |
| `env` | Show environment variables | `env` |
| `date` | Show/set system date | `date "+%Y-%m-%d %H:%M:%S"` |
| `cal` | Display a calendar | `cal` |

```bash
free -h                    # memory: total, used, free, available
df -h                       # disk space per mounted filesystem
du -sh /var/log/*            # size of each item in a directory
top -o %MEM                   # sort top by memory usage
uptime                          # load averages (1, 5, 15 min)
```

---

## 7. Networking

| Command | Description | Example |
|---|---|---|
| `ip a` | Show IP addresses (modern) | `ip a` |
| `ifconfig` | Show/configure interfaces (legacy) | `ifconfig` |
| `ping` | Test connectivity to a host | `ping -c 4 google.com` |
| `curl` | Transfer data / test HTTP endpoints | `curl -I https://example.com` |
| `wget` | Download files from the web | `wget https://example.com/file.zip` |
| `netstat` | Network connections/ports (legacy) | `netstat -tulpn` |
| `ss` | Socket statistics (modern replacement) | `ss -tulpn` |
| `traceroute` | Trace the network path to a host | `traceroute google.com` |
| `nslookup` | DNS lookup | `nslookup example.com` |
| `dig` | Detailed DNS lookup | `dig example.com A` |
| `host` | Simple DNS lookup | `host example.com` |
| `scp` | Secure copy over SSH | `scp file.txt user@host:/path/` |
| `rsync` | Efficient file sync (local/remote) | `rsync -avz src/ user@host:/dest/` |
| `nc` (netcat) | Network Swiss Army knife | `nc -zv host 22` (port check) |
| `iptables` | Configure firewall rules (legacy) | `iptables -L` |
| `ufw` | Uncomplicated firewall (Ubuntu) | `ufw allow 22/tcp` |
| `firewall-cmd` | Firewall management (RHEL/CentOS) | `firewall-cmd --list-all` |

### Common Networking Examples

```bash
ip a                                  # list all interfaces and IPs
ss -tulpn                              # all listening TCP/UDP ports with PIDs
curl -I https://example.com              # HTTP headers only
curl -X POST -d '{"key":"val"}' \        # POST JSON
  -H "Content-Type: application/json" \
  https://api.example.com/endpoint
wget -c https://example.com/large.zip      # resume a partial download
scp -r ./project user@server:/home/user/     # copy directory over SSH
rsync -avz --delete ./local/ user@host:/remote/  # mirror, deleting extras
dig +short example.com                          # just the IP
```

---

## 8. Package Management

### Debian / Ubuntu (`apt`)

| Command | Description |
|---|---|
| `apt update` | Refresh package index |
| `apt upgrade` | Upgrade installed packages |
| `apt install <pkg>` | Install a package |
| `apt remove <pkg>` | Remove a package (keep config) |
| `apt purge <pkg>` | Remove a package and its config |
| `apt autoremove` | Remove unused dependencies |
| `apt search <term>` | Search for a package |
| `apt list --installed` | List installed packages |
| `dpkg -i package.deb` | Install a local `.deb` file |
| `dpkg -l` | List installed packages (dpkg-level) |

### RHEL / CentOS / Fedora (`yum` / `dnf`)

| Command | Description |
|---|---|
| `dnf update` | Update all packages |
| `dnf install <pkg>` | Install a package |
| `dnf remove <pkg>` | Remove a package |
| `dnf search <term>` | Search for a package |
| `dnf list installed` | List installed packages |
| `rpm -ivh package.rpm` | Install a local `.rpm` file |
| `rpm -qa` | List installed packages (rpm-level) |

### Universal / Language-Specific

| Command | Description |
|---|---|
| `snap install <pkg>` | Install a Snap package |
| `pip install <pkg>` | Install a Python package |
| `npm install <pkg>` | Install a Node.js package |
| `brew install <pkg>` | Install via Homebrew (macOS/Linux) |

---

## 9. Disk & Storage Management

| Command | Description | Example |
|---|---|---|
| `mount` | Mount a filesystem | `mount /dev/sdb1 /mnt/data` |
| `umount` | Unmount a filesystem | `umount /mnt/data` |
| `fdisk` | Partition management (MBR) | `fdisk -l` |
| `parted` | Partition management (GPT-capable) | `parted /dev/sdb print` |
| `mkfs` | Create a filesystem | `mkfs.ext4 /dev/sdb1` |
| `fsck` | Check/repair a filesystem | `fsck /dev/sdb1` |
| `blkid` | Show block device UUIDs/types | `blkid` |
| `df -h` | Disk space usage | `df -h` |
| `du -h` | Directory/file space usage | `du -h --max-depth=1` |
| `lsblk` | Tree view of block devices | `lsblk -f` |

```bash
lsblk -f                          # devices, filesystems, mount points
df -hT                              # disk usage with filesystem type
du -h --max-depth=1 / | sort -rh    # largest top-level directories
mount /dev/sdb1 /mnt/data             # mount a device
echo "/dev/sdb1 /mnt/data ext4 defaults 0 0" >> /etc/fstab  # persist across reboot
```

---

## 10. User & Group Management

| Command | Description | Example |
|---|---|---|
| `useradd` | Create a new user | `useradd -m -s /bin/bash newuser` |
| `usermod` | Modify a user account | `usermod -aG sudo newuser` |
| `userdel` | Delete a user | `userdel -r newuser` (`-r` removes home dir) |
| `passwd` | Change a user's password | `passwd newuser` |
| `groupadd` | Create a new group | `groupadd developers` |
| `groupdel` | Delete a group | `groupdel developers` |
| `groups` | Show groups a user belongs to | `groups newuser` |
| `id` | Show UID/GID info | `id newuser` |
| `su` | Switch user | `su - newuser` |
| `sudo` | Execute as another user (default root) | `sudo apt update` |
| `whoami` | Show current effective user | `whoami` |
| `chsh` | Change a user's login shell | `chsh -s /bin/zsh newuser` |
| `visudo` | Safely edit sudoers file | `visudo` |

```bash
useradd -m -s /bin/bash -G sudo,docker deploy   # create user with groups
passwd deploy                                    # set password
usermod -aG docker existinguser                  # add existing user to a group
id deploy                                        # verify UID/GID/groups
```

---

## 11. Archiving & Compression

| Command | Description | Example |
|---|---|---|
| `tar -czvf` | Create a gzip-compressed archive | `tar -czvf backup.tar.gz /data` |
| `tar -xzvf` | Extract a gzip archive | `tar -xzvf backup.tar.gz` |
| `tar -cjvf` | Create a bzip2-compressed archive | `tar -cjvf backup.tar.bz2 /data` |
| `zip` | Create a zip archive | `zip -r archive.zip folder/` |
| `unzip` | Extract a zip archive | `unzip archive.zip -d output/` |
| `gzip` | Compress a single file | `gzip file.txt` → `file.txt.gz` |
| `gunzip` | Decompress a `.gz` file | `gunzip file.txt.gz` |
| `7z` | 7-Zip archive tool | `7z a archive.7z folder/` |

### `tar` Flag Reference

| Flag | Meaning |
|---|---|
| `-c` | Create archive |
| `-x` | Extract archive |
| `-z` | Use gzip compression |
| `-j` | Use bzip2 compression |
| `-v` | Verbose output |
| `-f` | Specify filename (must come last before the filename) |
| `-t` | List archive contents without extracting |

```bash
tar -tzvf archive.tar.gz              # list contents without extracting
tar -czvf backup.tar.gz --exclude='*.log' /data   # exclude a pattern
```

---

## 12. SSH & Remote Access

| Command | Description | Example |
|---|---|---|
| `ssh` | Connect to a remote host | `ssh user@host` |
| `ssh -i` | Connect using a specific key | `ssh -i key.pem user@host` |
| `ssh-keygen` | Generate an SSH key pair | `ssh-keygen -t ed25519 -C "you@email.com"` |
| `ssh-copy-id` | Copy your public key to a remote host | `ssh-copy-id user@host` |
| `scp` | Copy files over SSH | `scp file.txt user@host:/path/` |
| `sftp` | Interactive secure file transfer | `sftp user@host` |

```bash
ssh -i ~/.ssh/my-key.pem ec2-user@203.0.113.10
ssh -L 5432:localhost:5432 user@bastion         # local port forwarding
ssh -p 2222 user@host                           # custom port
scp -r ./local-folder user@host:/remote/path/     # recursive copy
```

### SSH Config Shortcut (`~/.ssh/config`)

```
Host myserver
    HostName 203.0.113.10
    User ec2-user
    IdentityFile ~/.ssh/my-key.pem
    Port 22
```
Then simply: `ssh myserver`

---

## 13. Scheduling & Automation

| Command | Description | Example |
|---|---|---|
| `crontab -e` | Edit the current user's cron jobs | `crontab -e` |
| `crontab -l` | List current cron jobs | `crontab -l` |
| `at` | Schedule a one-time command | `echo "backup.sh" \| at 02:00` |
| `systemctl` | Manage systemd services | `systemctl restart nginx` |
| `service` | Manage services (legacy/SysV) | `service nginx restart` |

### Cron Syntax

```
* * * * * command
│ │ │ │ │
│ │ │ │ └── day of week (0-7, 0 and 7 = Sunday)
│ │ │ └──── month (1-12)
│ │ └────── day of month (1-31)
│ └──────── hour (0-23)
└────────── minute (0-59)
```

```bash
0 2 * * *      /home/user/backup.sh          # daily at 2:00 AM
*/15 * * * *   /home/user/check.sh            # every 15 minutes
0 9 * * 1-5    /home/user/weekday_report.sh    # weekdays at 9 AM
0 0 1 * *      /home/user/monthly_cleanup.sh    # first day of every month
```

### systemctl Common Commands

```bash
systemctl status nginx        # check status
systemctl start nginx         # start a service
systemctl stop nginx          # stop a service
systemctl restart nginx       # restart
systemctl enable nginx        # start on boot
systemctl disable nginx       # don't start on boot
systemctl daemon-reload       # reload unit files after editing
journalctl -u nginx -f        # follow live logs for a service
```

---

## 14. System Logs

| Command | Description | Example |
|---|---|---|
| `journalctl` | Query systemd journal logs | `journalctl -xe` |
| `tail -f` | Follow a log file live | `tail -f /var/log/syslog` |
| `dmesg` | Kernel boot/driver messages | `dmesg -T` (human-readable timestamps) |
| `less /var/log/auth.log` | View authentication log | (Debian/Ubuntu) |
| `less /var/log/messages` | View general system log | (RHEL/CentOS) |

```bash
journalctl -u sshd --since "1 hour ago"       # logs for a specific service
journalctl -f                                  # follow all logs live
journalctl -p err -b                           # errors since last boot
journalctl --disk-usage                        # check journal log size
```

---

## 15. Shell Scripting Essentials

### Basic Script Structure

```bash
#!/bin/bash
set -euo pipefail   # exit on error, undefined var, or pipe failure

echo "Starting script..."

# Variables
NAME="World"
echo "Hello, $NAME"

# Conditionals
if [ -f "/etc/hosts" ]; then
    echo "File exists"
fi

# Loops
for i in 1 2 3; do
    echo "Iteration $i"
done

# Functions
greet() {
    local name=$1
    echo "Hello, $name"
}
greet "AWS"
```

### Comparison Operators (Test Conditions)

| Operator | Meaning |
|---|---|
| `-f file` | File exists and is a regular file |
| `-d dir` | Directory exists |
| `-z string` | String is empty |
| `-n string` | String is not empty |
| `-eq` / `-ne` | Numeric equal / not equal |
| `-gt` / `-lt` | Numeric greater than / less than |
| `==` / `!=` | String equal / not equal |

### Making a Script Executable

```bash
chmod +x script.sh
./script.sh
# or run without chmod:
bash script.sh
```

---

## 16. Environment Variables

| Command | Description | Example |
|---|---|---|
| `export VAR=value` | Set an environment variable for the session | `export API_KEY=abc123` |
| `unset VAR` | Remove an environment variable | `unset API_KEY` |
| `echo $VAR` | Print a variable's value | `echo $HOME` |
| `env` | List all environment variables | `env` |
| `printenv` | Print specific/all env variables | `printenv PATH` |
| `source` / `.` | Reload a shell config file | `source ~/.bashrc` |

### Common Environment Variables

| Variable | Purpose |
|---|---|
| `$HOME` | Current user's home directory |
| `$PATH` | Directories searched for executables |
| `$USER` | Current username |
| `$PWD` | Current working directory |
| `$SHELL` | Current shell path |
| `$?` | Exit status of the last command |
| `$$` | PID of the current shell |

```bash
export PATH=$PATH:/opt/myapp/bin      # add to PATH
echo $?                                # check if last command succeeded (0 = success)
```

---

## 17. Useful Command Combinations

```bash
# Find the top 10 largest files in a directory
du -ah /var | sort -rh | head -10

# Find and kill a process listening on a specific port
lsof -i :8080
kill -9 $(lsof -t -i:8080)

# Count occurrences of each unique line
sort file.txt | uniq -c | sort -rn

# Search for a string across all files in a directory, recursively
grep -rn "TODO" --include="*.py" .

# Watch disk usage update every 2 seconds
watch -n 2 df -h

# Monitor a log file and highlight errors in real time
tail -f app.log | grep --color=always -i error

# Check which process is using the most memory
ps aux --sort=-%mem | head -10

# Bulk rename files (change .txt to .bak)
for f in *.txt; do mv "$f" "${f%.txt}.bak"; done

# Find all files modified in the last 24 hours
find . -mtime -1 -type f

# Compress and timestamp a backup
tar -czvf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" /data

# Check open ports and the process using each
sudo ss -tulpn

# Test if a remote port is reachable
nc -zv example.com 443

# Show disk I/O per process (if iotop installed)
sudo iotop -o
```

---

## Quick Reference: Command Categories

| Task | Go-To Commands |
|---|---|
| Navigate/manage files | `ls`, `cd`, `cp`, `mv`, `rm`, `find` |
| Check permissions | `chmod`, `chown`, `stat` |
| Read/search text | `cat`, `less`, `grep`, `sed`, `awk` |
| Manage processes | `ps`, `top`, `kill`, `systemctl` |
| Check system health | `df`, `free`, `uptime`, `top` |
| Network diagnostics | `ip`, `ping`, `curl`, `ss`, `dig` |
| Install software | `apt`/`dnf`, `pip`, `npm` |
| Transfer files remotely | `scp`, `rsync`, `sftp` |
| Automate tasks | `crontab`, `systemctl`, shell scripts |
| Investigate issues | `journalctl`, `dmesg`, `tail -f` |

---

## Next Steps / Advanced Topics

- **Regular expressions** — deepen `grep`/`sed`/`awk` skills with regex patterns
- **Shell scripting** — loops, functions, error handling, argument parsing (`getopts`)
- **Process substitution & pipes** — chaining commands for complex one-liners
- **systemd unit files** — writing custom services for your own applications
- **Configuration management** — Ansible, Puppet, or Chef for managing many servers declaratively
