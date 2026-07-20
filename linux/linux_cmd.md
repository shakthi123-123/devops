# WSL & Linux Command Reference

## Table of Contents
1. [WSL Commands (PowerShell)](#1-wsl-commands-powershell)
2. [Add New Root User](#2-add-new-root-user)
3. [Basic System & Navigation Commands](#3-basic-system--navigation-commands)
4. [File and Directory Commands](#4-file-and-directory-commands)
5. [Networking Commands](#5-networking-commands)
6. [Process and System Monitoring Commands](#6-process-and-system-monitoring-commands)
7. [User and Permission Management Commands](#7-user-and-permission-management-commands)
8. [File Transfer and Synchronization Commands](#8-file-transfer-and-synchronization-commands)
9. [Text Processing Commands](#9-text-processing-commands)
10. [Shell Utilities and Shortcuts](#10-shell-utilities-and-shortcuts)

---

## 1. WSL Commands (PowerShell)

| Command | Description |
|---|---|
| `wsl --list --online` | List available Linux distros |
| `wsl --install ubuntu` | Install WSL with Ubuntu |
| `wsl ~` | Start WSL |
| `wsl --shutdown` | Stop WSL |
| `wsl -l -v` | Show status/version of installed distros |
| `wsl --unregister Ubuntu` | Remove Ubuntu WSL install from Windows |

---

## 2. Add New Root User

| Command | Description |
|---|---|
| `sudo adduser <new_user>` | Add a new user |
| `getent passwd \| grep <new_user>` | Check if user exists in passwd database |
| `sudo usermod -aG sudo <new_user>` | Add user to the `sudo` group |
| `groups <username>` | Show groups a user belongs to |
| `sudo visudo` | Safely edit the sudoers file |
| `sudo whoami` | Show effective user (should print `root`) |
| `sudo passwd root` | Set/change the root password |
| `su -` | Switch to root with root's environment |
| `sudo su` | Get root access via sudo |

---

## 3. Basic System & Navigation Commands

| Command | Description |
|---|---|
| `lsb_release -a` | Display Linux distribution/version info |
| `ls -lstr` | List all files (long, sorted by time, reversed) |
| `uname` | Display system info |
| `cd <directory>` | Change working directory |
| `pwd` | Show working directory |
| `mkdir <directory>` | Create a directory |
| `touch <file>` | Create a new file |
| `rmdir <directory>` | Remove an empty directory |
| `rm <file>` | Remove a file |
| `cp file1.txt file2.txt` | Copy a file to another file |
| `cat file1 > file2` | Copy contents of one file into another |
| `mv file1.txt file2.txt` | Move/rename a file |
| `echo "New text"` | Insert/print a line of text |
| `vim <file>` | Edit a file (Vim) |
| `nano <file>` | Edit a file (Nano) |
| `cat <file>` | Display file contents |
| `locate <name>` | Find the location of a file |
| `ln -s <src> <dest>` | Create a symbolic link between two files |
| `Ctrl + C` | Kill/interrupt a stuck process in the terminal |
| `tail <file>` | Show the last 10 lines of a file |
| `tail -f <file>` | Follow a file's new content in real time |

---

## 4. File and Directory Commands

| Command | Description | Example |
|---|---|---|
| `ls` | List directory contents | `ls` |
| `cd` | Change directory | `cd /path/to/directory` |
| `pwd` | Show current directory | `pwd` |
| `mkdir` | Create a new directory | `mkdir new_directory` |
| `rmdir` | Remove an empty directory | `rmdir empty_directory` |
| `rm` | Delete files or directories | `rm file.txt` |
| `touch` | Create an empty file | `touch new_file.txt` |
| `cp` | Copy files or directories | `cp file.txt /path/to/destination` |
| `mv` | Move or rename files | `mv file.txt /path/to/new_location` |
| `cat` | Display file contents | `cat file.txt` |
| `nano` / `vim` | Edit files in terminal | `nano file.txt` |
| `find` | Search for files in a directory hierarchy | `find . -name "file.txt"` |
| `grep` | Search text using patterns | `grep "pattern" file.txt` |
| `tar` | Archive and compress files | `tar -cvf archive.tar file1.txt file2.txt` |
| `df` | Show disk usage of file systems | `df` |
| `du` | Show directory/file size | `du -sh /path/to/directory` |
| `chmod` | Change file permissions | `chmod 755 file.txt` |
| `chown` | Change file owner | `chown user:group file.txt` |
| `mount` | Mount a filesystem | `mount /dev/sdb1 /mnt` |
| `umount` | Unmount a filesystem | `umount /mnt` |

---

## 5. Networking Commands

| Command | Description | Example |
|---|---|---|
| `ping` | Test connectivity to a host | `ping google.com` |
| `ifconfig` / `ip a` | Display network interfaces | `ifconfig` or `ip a` |
| `netstat` / `ss` | Show network connections | `netstat -tuln` or `ss -tuln` |
| `wget` | Download files via HTTP/FTP | `wget http://example.com/file.zip` |
| `curl` | Transfer data using URL syntax | `curl -O http://example.com/file.zip` |
| `nc` (Netcat) | Network debugging and data transfer | `nc -zv 192.168.1.1 80` |
| `tcpdump` | Capture and analyze network packets | `tcpdump -i eth0` |
| `iptables` | Configure firewall rules | `iptables -A INPUT -p tcp --dport 22 -j ACCEPT` |
| `traceroute` | Trace the path packets take to a network host | `traceroute example.com` |
| `nslookup` | Query DNS to obtain domain name or IP address mapping | `nslookup example.com` |
| `ssh` | Securely connect to a remote host | `ssh user@example.com` |

---

## 6. Process and System Monitoring Commands

| Command | Description | Example |
|---|---|---|
| `ps` | Show running processes | `ps aux` |
| `top` | Dynamic process viewer | `top` |
| `htop` | Enhanced version of `top` | `htop` |
| `kill` | Send a signal to a process | `kill <PID>` |
| `killall` | Kill processes by name | `killall <process_name>` |
| `uptime` | System uptime and load | `uptime` |
| `whoami` | Current logged-in user | `whoami` |
| `env` | Display environment variables | `env` |
| `strace` | Trace system calls of a process | `strace -p <PID>` |
| `systemctl` | Manage systemd services | `systemctl status <service_name>` |
| `journalctl` | View system logs | `journalctl -xe` |
| `free` | Display memory usage | `free -h` |
| `vmstat` | Report virtual memory statistics | `vmstat 1` |
| `iostat` | Report CPU and I/O statistics | `iostat` |
| `lsof` | List open files by processes | `lsof` |
| `dmesg` | Print kernel ring buffer messages | `dmesg` |

---

## 7. User and Permission Management Commands

| Command | Description | Example |
|---|---|---|
| `passwd` | Change user password | `passwd <username>` |
| `adduser` / `useradd` | Add a new user | `adduser <username>` or `useradd <username>` |
| `deluser` / `userdel` | Delete a user | `deluser <username>` or `userdel <username>` |
| `usermod` | Modify user account | `usermod -aG <group> <username>` |
| `groups` | Show group memberships | `groups <username>` |
| `sudo` | Execute commands as root | `sudo <command>` |
| `chage` | Change user password expiry information | `chage -l <username>` |
| `id` | Display user identity information | `id <username>` |
| `newgrp` | Log in to a new group | `newgrp <group>` |

---

## 8. File Transfer and Synchronization Commands

| Command | Description | Example |
|---|---|---|
| `scp` | Securely copy files over SSH | `scp user@remote:/path/to/file /local/destination` |
| `rsync` | Efficiently sync files and directories | `rsync -avz /local/directory/ user@remote:/path/to/destination` |
| `ftp` | Transfer files using the File Transfer Protocol | `ftp ftp.example.com` |
| `sftp` | Securely transfer files using SSH File Transfer Protocol | `sftp user@remote:/path/to/file` |
| `wget` | Download files from the web | `wget http://example.com/file.zip` |
| `curl` | Transfer data from or to a server | `curl -O http://example.com/file.zip` |

---

## 9. Text Processing Commands

| Command | Description | Example |
|---|---|---|
| `awk` | Pattern scanning and processing | `awk '{print $1}' file.txt` |
| `sed` | Stream editor for filtering/modifying text | `sed 's/old/new/g' file.txt` |
| `cut` | Remove sections from lines of text | `cut -d':' -f1 /etc/passwd` |
| `sort` | Sort lines of text | `sort file.txt` |
| `grep` | Search for patterns in text | `grep 'pattern' file.txt` |
| `pgrep` | Search for processes by name/pattern | `pgrep nginx` |
| `wc` | Count words, lines, and characters | `wc -l file.txt` |
| `paste` | Merge lines of files | `paste file1.txt file2.txt` |
| `join` | Join lines of two files on a common field | `join file1.txt file2.txt` |
| `head` | Output the first part of files | `head -n 10 file.txt` |
| `tail` | Output the last part of files | `tail -n 10 file.txt` |

---

## 10. Shell Utilities and Shortcuts

| Command | Description | Example |
|---|---|---|
| `alias` | Create shortcuts for commands | `alias ll='ls -la'` |
| `unalias` | Remove an alias | `unalias ll` |
| `history` | Show previously entered commands | `history` |
| `clear` | Clear the terminal screen | `clear` |
| `reboot` | Reboot the system | `reboot` |
| `shutdown` | Power off the system | `shutdown now` |
| `date` | Display or set the system date and time | `date` |
| `echo` | Display a line of text | `echo "Hello, World!"` |
| `sleep` | Delay for a specified amount of time | `sleep 5` |
| `time` | Measure the duration of command execution | `time ls` |
| `watch` | Execute a program periodically, showing output fullscreen | `watch -n 5 df -h` |
