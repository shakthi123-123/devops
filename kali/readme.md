# Kali Linux — Penetration Testing Command Reference

> ⚠️ **Legal & Ethical Use Only**
> These tools are built for **authorized security testing** — on systems you own, or with explicit written permission (e.g. a signed penetration testing agreement / bug bounty scope). Running these against systems you don't have permission to test is illegal in most jurisdictions (e.g. under the U.S. Computer Fraud and Abuse Act, UK Computer Misuse Act, and equivalents elsewhere) and can result in criminal charges. Always work within a defined scope, get sign-off, and document your testing.

## Table of Contents
1. [Reconnaissance / Information Gathering](#1-reconnaissance--information-gathering)
2. [Network Scanning](#2-network-scanning)
3. [Vulnerability Analysis](#3-vulnerability-analysis)
4. [Web Application Testing](#4-web-application-testing)
5. [Password Attacks](#5-password-attacks)
6. [Wireless Testing](#6-wireless-testing)
7. [Sniffing & Spoofing](#7-sniffing--spoofing)
8. [Exploitation Frameworks](#8-exploitation-frameworks)
9. [Post-Exploitation](#9-post-exploitation)
10. [Forensics](#10-forensics)
11. [Reporting](#11-reporting)

---

## 1. Reconnaissance / Information Gathering

| Command | Description |
|---|---|
| `whois example.com` | Domain registration lookup |
| `nslookup example.com` | Basic DNS lookup |
| `dig example.com ANY` | Detailed DNS record query |
| `theHarvester -d example.com -b google` | Gather emails/subdomains from public sources |
| `recon-ng` | Modular web reconnaissance framework |
| `dnsenum example.com` | DNS enumeration (zone transfers, subdomains) |
| `sublist3r -d example.com` | Subdomain enumeration |
| `maltego` | Visual link-analysis OSINT tool (GUI) |
| `shodan search <query>` | Search Shodan for exposed devices/services (needs API key) |

---

## 2. Network Scanning

| Command | Description |
|---|---|
| `nmap -sn 192.168.1.0/24` | Ping sweep — discover live hosts |
| `nmap -sS -p- 192.168.1.10` | Full TCP SYN scan, all 65535 ports |
| `nmap -sV -O 192.168.1.10` | Service version + OS detection |
| `nmap -A 192.168.1.10` | Aggressive scan (OS, version, scripts, traceroute) |
| `nmap --script vuln 192.168.1.10` | Run NSE vulnerability scripts |
| `masscan -p1-65535 192.168.1.0/24 --rate=1000` | Very fast large-range port scanner |
| `netdiscover -r 192.168.1.0/24` | ARP-based host discovery on local network |
| `arp-scan --localnet` | Scan local subnet via ARP |

---

## 3. Vulnerability Analysis

| Command | Description |
|---|---|
| `nikto -h http://target.com` | Web server vulnerability scanner |
| `openvas-start` | Launch OpenVAS vulnerability scanner |
| `nmap --script vuln -p 445 <target>` | Check specific ports for known vulnerabilities |
| `searchsploit apache 2.4.49` | Search local Exploit-DB copy for known exploits |
| `wpscan --url http://target.com` | WordPress-specific vulnerability scanner |
| `legion` | GUI-based automated recon/vuln scanning |

---

## 4. Web Application Testing

| Command | Description |
|---|---|
| `burpsuite` | Web proxy/intercept, manual + automated web testing (GUI) |
| `sqlmap -u "http://target.com/page?id=1" --dbs` | Automated SQL injection detection & DB enumeration |
| `dirb http://target.com` | Brute-force directories/files on a web server |
| `gobuster dir -u http://target.com -w wordlist.txt` | Faster directory/file brute-forcing |
| `wfuzz -c -z file,wordlist.txt http://target.com/FUZZ` | Web fuzzing (params, dirs, subdomains) |
| `xsstrike -u "http://target.com/page?q=test"` | XSS vulnerability scanner |
| `commix --url="http://target.com/page?id=1"` | Command injection testing tool |

---

## 5. Password Attacks

| Command | Description |
|---|---|
| `hydra -l admin -P rockyou.txt ssh://192.168.1.10` | Brute-force SSH login |
| `hydra -L users.txt -P passwords.txt <target> http-post-form "..."` | Brute-force a web login form |
| `john --wordlist=rockyou.txt hashes.txt` | Crack password hashes with a wordlist |
| `john --format=nt hashes.txt` | Crack NTLM hashes |
| `hashcat -m 0 -a 0 hashes.txt rockyou.txt` | GPU-accelerated hash cracking (mode 0 = MD5) |
| `crunch 8 8 -t @@@@%%%% -o wordlist.txt` | Generate a custom wordlist by pattern |
| `medusa -h <target> -u admin -P passwords.txt -M ssh` | Alternative parallel login brute-forcer |

---

## 6. Wireless Testing

| Command | Description |
|---|---|
| `airmon-ng start wlan0` | Put wireless adapter into monitor mode |
| `airodump-ng wlan0mon` | Capture nearby wireless networks/traffic |
| `airodump-ng -c <channel> --bssid <BSSID> -w capture wlan0mon` | Capture handshake for a specific AP |
| `aireplay-ng --deauth 10 -a <BSSID> wlan0mon` | Send deauth packets to force a handshake (needs authorization) |
| `aircrack-ng capture.cap -w rockyou.txt` | Crack WPA/WPA2 handshake with a wordlist |
| `wifite` | Automated wireless auditing tool |
| `reaver -i wlan0mon -b <BSSID> -vv` | WPS PIN brute-force attack |

---

## 7. Sniffing & Spoofing

| Command | Description |
|---|---|
| `wireshark` | GUI packet capture & analysis |
| `tcpdump -i eth0 -w capture.pcap` | Command-line packet capture |
| `ettercap -G` | GUI-based MITM sniffing/spoofing |
| `arpspoof -i eth0 -t <target-ip> <gateway-ip>` | ARP spoofing for MITM (needs authorization) |
| `bettercap -iface eth0` | Modern all-in-one MITM/network attack framework |
| `dnsspoof -i eth0` | DNS spoofing (used alongside ARP spoofing) |

---

## 8. Exploitation Frameworks

| Command | Description |
|---|---|
| `msfconsole` | Launch the Metasploit Framework console |
| `search <cve or keyword>` | (inside msfconsole) search for an exploit module |
| `use exploit/<path>` | (inside msfconsole) select an exploit module |
| `set RHOSTS <target-ip>` | (inside msfconsole) set the target |
| `set PAYLOAD <payload>` | (inside msfconsole) select a payload |
| `exploit` / `run` | (inside msfconsole) launch the exploit |
| `msfvenom -p <payload> LHOST=<ip> LPORT=<port> -f exe -o shell.exe` | Generate a standalone payload |
| `armitage` | GUI front-end for Metasploit |

---

## 9. Post-Exploitation

| Command | Description |
|---|---|
| `sessions -l` | (inside msfconsole) list active sessions |
| `sessions -i <id>` | Interact with a specific session |
| `getsystem` | (Meterpreter) attempt privilege escalation |
| `hashdump` | (Meterpreter) dump password hashes from a compromised Windows host |
| `mimikatz` | Extract Windows credentials from memory (used within an authorized engagement) |
| `linpeas.sh` | Linux privilege escalation enumeration script |
| `winpeas.exe` | Windows privilege escalation enumeration script |
| `chisel` / `ligolo-ng` | Pivoting/tunneling into internal networks post-compromise |

---

## 10. Forensics

| Command | Description |
|---|---|
| `autopsy` | GUI digital forensics platform |
| `binwalk firmware.bin` | Analyze/extract data from firmware images |
| `foremost -i disk.img -o output/` | Recover files from a disk image |
| `volatility -f memory.dump imageinfo` | Memory forensics — identify OS profile |
| `exiftool image.jpg` | Extract metadata from files |
| `strings binary_file` | Extract readable strings from a binary |

---

## 11. Reporting

Documentation is a core part of any legitimate engagement — findings without a clear, reproducible report have little value.

| Tool | Purpose |
|---|---|
| `dradis` | Collaboration & reporting platform for pentest teams |
| `faraday` | Vulnerability management & reporting platform |
| CherryTree / Obsidian | Note-taking during engagements (manual) |

**A good finding typically includes:** vulnerability description, affected asset, steps to reproduce, evidence (screenshots/output), CVSS score, and remediation guidance.

---

## Recommended Legal Practice Environments

If you want to practice these commands hands-on, use environments explicitly built for it rather than testing on systems you don't own:
- [Hack The Box](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)
- [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) (deliberately vulnerable web app)
- [Metasploitable](https://sourceforge.net/projects/metasploitable/) (deliberately vulnerable VM)
- [VulnHub](https://www.vulnhub.com/)
