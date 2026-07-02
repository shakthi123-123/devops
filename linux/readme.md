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
