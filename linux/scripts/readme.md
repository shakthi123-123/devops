# Bash Scripting — Detailed Reference with Options & Examples

## 1. Script Basics

```bash
#!/bin/bash
# Shebang line — tells the OS which interpreter to use
echo "Hello, World!"
```

```bash
chmod +x script.sh    # make executable
./script.sh             # run it
bash script.sh            # or run explicitly with bash
```

| Shebang | Meaning |
|---|---|
| `#!/bin/bash` | Use bash specifically |
| `#!/bin/sh` | Use the system's default shell (may be dash, more POSIX-strict) |
| `#!/usr/bin/env bash` | Find bash via `PATH` — more portable across systems |

---

## 2. `bash` Command-Line Options

These are flags passed to the `bash` interpreter itself (not inside a script).

| Option | Meaning | Example |
|---|---|---|
| `-c` | Run a command string | `bash -c 'echo hi'` |
| `-x` | Print each command before executing (trace mode) | `bash -x script.sh` |
| `-n` | Syntax check only, don't execute | `bash -n script.sh` |
| `-e` | Exit immediately if a command fails | `bash -e script.sh` |
| `-u` | Error on unset variables | `bash -u script.sh` |
| `-v` | Print shell input lines as read | `bash -v script.sh` |
| `-i` | Interactive shell | `bash -i` |
| `-l` | Act as login shell | `bash -l` |
| `-r` | Restricted shell | `bash -r` |
| `--posix` | POSIX-compliant mode | `bash --posix script.sh` |
| `--version` | Show bash version | `bash --version` |

These can also be set **inside** a script with `set`:
```bash
set -e     # exit on error
set -u     # error on unset variable
set -x     # trace execution
set -o pipefail   # fail if any command in a pipeline fails
set -euo pipefail  # the common "strict mode" combo
```

---

## 3. Variables

```bash
name="Alice"                # no spaces around =
echo "$name"                  # use variable
echo "${name}"                  # explicit braces (safer with concatenation)
readonly PI=3.14                  # constant, can't be reassigned
unset name                          # delete a variable

# Numeric
count=5
((count++))                          # arithmetic increment
echo $((count * 2))                    # arithmetic expansion

# Environment variables
export MY_VAR="value"                    # available to child processes
echo "$HOME $USER $PATH $PWD $SHELL"       # common built-ins

# Default/fallback values
echo "${name:-default}"    # use "default" if name is unset/empty
echo "${name:=default}"    # same, but also assigns it
echo "${name:+alt}"        # use "alt" only if name IS set
echo "${name:?error msg}"  # error out if name is unset
```

---

## 4. String Operations

```bash
str="Hello World"

echo "${#str}"           # length → 11
echo "${str:0:5}"        # substring → "Hello"
echo "${str,,}"           # lowercase → "hello world"
echo "${str^^}"            # uppercase → "HELLO WORLD"
echo "${str/World/Bash}"    # replace first match → "Hello Bash"
echo "${str//o/0}"           # replace all matches → "Hell0 W0rld"
echo "${str#Hello }"           # strip shortest match from front
echo "${str%World}"              # strip shortest match from end
echo "${str%%o*}"                  # strip longest match from end

# Concatenation
a="foo"; b="bar"
echo "$a$b"          # foobar
echo "${a}_${b}"       # foo_bar

# Splitting into array
IFS=',' read -ra parts <<< "a,b,c"
echo "${parts[1]}"    # b
```

---

## 5. Arrays

```bash
# Indexed array
fruits=("apple" "banana" "cherry")
echo "${fruits[0]}"        # apple
echo "${fruits[@]}"        # all elements
echo "${#fruits[@]}"       # length: 3
fruits+=("date")           # append
unset fruits[1]             # remove element by index

for f in "${fruits[@]}"; do
  echo "$f"
done

# Associative array (bash 4+)
declare -A ages
ages["Alice"]=30
ages["Bob"]=25
echo "${ages[Alice]}"
for key in "${!ages[@]}"; do
  echo "$key -> ${ages[$key]}"
done
```

---

## 6. Conditionals

### 6.1 `if` / `elif` / `else`
```bash
if [ "$1" == "yes" ]; then
  echo "Confirmed"
elif [ "$1" == "no" ]; then
  echo "Denied"
else
  echo "Unknown"
fi
```

### 6.2 Test Operators — `[ ]` vs `[[ ]]`

| Type | Operator | Meaning |
|---|---|---|
| String | `==`, `!=` | equal / not equal |
| String | `-z "$s"` | string is empty |
| String | `-n "$s"` | string is non-empty |
| Numeric | `-eq`, `-ne` | equal / not equal |
| Numeric | `-lt`, `-le` | less than / less-or-equal |
| Numeric | `-gt`, `-ge` | greater than / greater-or-equal |
| File | `-f file` | file exists and is a regular file |
| File | `-d dir` | directory exists |
| File | `-e path` | path exists (any type) |
| File | `-r`, `-w`, `-x` | readable / writable / executable |
| File | `-s file` | file exists and is non-empty |
| Logic | `&&`, `\|\|` | AND / OR (use inside `[[ ]]`) |
| Logic | `-a`, `-o` | AND / OR (legacy, inside `[ ]`) |

```bash
[[ -f "/etc/passwd" ]] && echo "exists"
[[ $num -gt 10 && $num -lt 20 ]] && echo "in range"
[[ "$str" =~ ^[0-9]+$ ]] && echo "is numeric"    # regex match, [[ ]] only
```
> Prefer `[[ ]]` over `[ ]`: it supports `&&`, `||`, `=~` (regex), and avoids word-splitting bugs.

### 6.3 `case` Statement
```bash
case "$1" in
  start)
    echo "Starting..."
    ;;
  stop)
    echo "Stopping..."
    ;;
  restart|reload)
    echo "Restarting..."
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    ;;
esac
```

---

## 7. Loops

### 7.1 `for`
```bash
for i in 1 2 3 4 5; do
  echo "$i"
done

for i in {1..10}; do echo "$i"; done          # range
for i in {0..20..5}; do echo "$i"; done         # range with step

for (( i=0; i<5; i++ )); do                       # C-style
  echo "$i"
done

for file in *.txt; do                               # glob
  echo "Processing $file"
done
```

### 7.2 `while`
```bash
count=0
while [ $count -lt 5 ]; do
  echo "$count"
  ((count++))
done

# Read file line by line
while IFS= read -r line; do
  echo "$line"
done < file.txt
```

### 7.3 `until`
```bash
count=0
until [ $count -ge 5 ]; do
  echo "$count"
  ((count++))
done
```

### 7.4 Loop Control
```bash
break        # exit loop entirely
continue     # skip to next iteration
break 2      # break out of 2 nested loops
```

---

## 8. Functions

```bash
greet() {
  local name="$1"          # 'local' scopes variable to function
  echo "Hello, $name!"
  return 0                    # return an exit code (0-255), not a value
}

greet "Alice"

# Capture output instead of exit code
result=$(greet "Bob")
echo "$result"

# Multiple arguments, $@ and $#
show_args() {
  echo "Count: $#"
  echo "All: $@"
  echo "First: $1, Second: $2"
}
show_args a b c
```

---

## 9. Positional Parameters & Special Variables

| Variable | Meaning |
|---|---|
| `$0` | Script name |
| `$1`, `$2`, ... | Positional arguments |
| `$#` | Number of arguments |
| `$@` | All arguments as separate words |
| `$*` | All arguments as a single string |
| `$?` | Exit status of last command |
| `$$` | PID of current script |
| `$!` | PID of last background process |
| `$_` | Last argument of previous command |

```bash
shift          # shifts $2→$1, $3→$2, etc.
shift 2        # shift by 2 positions
```

---

## 10. Input/Output & Redirection

```bash
command > file        # stdout to file (overwrite)
command >> file        # stdout to file (append)
command 2> file          # stderr to file
command &> file            # both stdout & stderr to file
command 2>&1                # redirect stderr to same place as stdout
command < file                # stdin from file
command <<< "string"            # here-string
command <<EOF                     # here-document
multi-line
input
EOF

command1 | command2      # pipe stdout of cmd1 into stdin of cmd2
command > /dev/null 2>&1   # discard all output entirely

read -p "Enter name: " name    # prompt + read input
read -s -p "Password: " pass     # silent read (no echo)
read -r line                       # -r prevents backslash escaping
```

---

## 11. Exit Codes & Error Handling

```bash
exit 0     # success
exit 1     # generic failure
exit 127   # command not found

command1 && command2    # run command2 only if command1 succeeds
command1 || command2    # run command2 only if command1 fails

command || { echo "Failed!"; exit 1; }

# trap: run cleanup code on exit/signal
trap 'echo "Cleaning up..."; rm -f /tmp/tempfile' EXIT
trap 'echo "Interrupted"; exit 1' INT TERM

# Strict mode (common at top of production scripts)
set -euo pipefail
IFS=$'\n\t'
```

---

## 12. Arithmetic

```bash
echo $((5 + 3))          # 8
echo $((10 / 3))           # 3 (integer division)
echo $((10 % 3))             # 1 (modulo)
echo $((2 ** 8))               # 256 (exponent)

let x=5+3                        # alternate arithmetic syntax
((x = 5 + 3))                       # arithmetic command
x=$((x + 1))                          # increment

# Floating point needs bc or awk (bash is integer-only)
echo "scale=2; 10/3" | bc
awk "BEGIN {print 10/3}"
```

---

## 13. Command Substitution

```bash
current_date=$(date +%F)         # preferred, modern syntax
current_date=`date +%F`           # legacy backtick syntax (avoid, hard to nest)

files=$(ls *.txt)
count=$(echo "$files" | wc -l)
```

---

## 14. Process Substitution & Background Jobs

```bash
diff <(sort file1) <(sort file2)   # treat command output as a file

long_running_task &      # run in background
wait                       # wait for all background jobs
wait $!                      # wait for specific PID
jobs -l                        # list background jobs
```

---

## 15. Debugging

| Technique | Command |
|---|---|
| Trace execution | `bash -x script.sh` or `set -x` / `set +x` |
| Syntax check only | `bash -n script.sh` |
| Verbose (echo input) | `bash -v script.sh` |
| Static analysis | `shellcheck script.sh` (external tool) |
| Print debug var | `echo "DEBUG: var=$var" >&2` |
| Trap on error | `trap 'echo "Error on line $LINENO"' ERR` |

---

## 16. Useful Script Patterns

### 16.1 Argument Parsing with `getopts`
```bash
#!/bin/bash
while getopts "u:p:vh" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    p) pass="$OPTARG" ;;
    v) verbose=true ;;
    h) echo "Usage: $0 -u user -p pass [-v]"; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG"; exit 1 ;;
  esac
done
echo "User: $user"
```
Run as: `./script.sh -u admin -p secret -v`

### 16.2 Checking if a Command Exists
```bash
if command -v git &> /dev/null; then
  echo "git is installed"
else
  echo "git not found"
fi
```

### 16.3 Reading a Config File
```bash
source config.sh     # or: . config.sh
```

### 16.4 Script Directory-Independent Paths
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### 16.5 Safe Temp Files
```bash
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
```

### 16.6 Looping Over Command Output Safely
```bash
find . -name "*.log" -print0 | while IFS= read -r -d '' file; do
  echo "$file"
done
```

---

## 17. Full Example Script

```bash
#!/usr/bin/env bash
#
# backup.sh — backs up a directory to a timestamped tarball
set -euo pipefail

SRC_DIR="${1:?Usage: $0 <source_dir> <dest_dir>}"
DEST_DIR="${2:?Usage: $0 <source_dir> <dest_dir>}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="${DEST_DIR}/backup_${TIMESTAMP}.tar.gz"

log() {
  echo "[$(date +%T)] $*"
}

cleanup() {
  log "Cleaning up temp files..."
}
trap cleanup EXIT

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Error: $SRC_DIR does not exist" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

log "Backing up $SRC_DIR to $ARCHIVE"
tar -czf "$ARCHIVE" -C "$(dirname "$SRC_DIR")" "$(basename "$SRC_DIR")"

if [[ $? -eq 0 ]]; then
  log "Backup successful: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
else
  log "Backup failed"
  exit 1
fi
```

Run: `./backup.sh /home/user/docs /home/user/backups`

---

## 18. Quick Reference Cheat Sheet

| Task | Syntax |
|---|---|
| Comment | `# comment` |
| Variable assignment | `var=value` (no spaces) |
| String test | `[[ "$a" == "$b" ]]` |
| Numeric test | `[[ $a -eq $b ]]` |
| File exists | `[[ -f file ]]` |
| Loop over array | `for x in "${arr[@]}"; do ... done` |
| Function | `func() { ...; }` |
| Command substitution | `$(command)` |
| Arithmetic | `$((expr))` |
| Exit on error | `set -e` |
| Read input | `read -p "prompt: " var` |
| Background job | `command &` |
| Redirect stdout+stderr | `command &> file` |

---

# Bash Operators & Example Scripts

## Numeric Comparison Operators

| Operator | Meaning | Example |
|---|---|---|
| `-eq` | Equal to | `[ "$a" -eq "$b" ]` |
| `-ne` | Not equal to | `[ "$a" -ne "$b" ]` |
| `-gt` | Greater than | `[ "$a" -gt "$b" ]` |
| `-ge` | Greater than or equal to | `[ "$a" -ge "$b" ]` |
| `-lt` | Less than | `[ "$a" -lt "$b" ]` |
| `-le` | Less than or equal to | `[ "$a" -le "$b" ]` |

## String Comparison Operators

| Operator | Meaning | Example |
|---|---|---|
| `=` or `==` | Equal to | `[ "$str1" = "$str2" ]` |
| `!=` | Not equal to | `[ "$str1" != "$str2" ]` |
| `-z` | True if string is empty | `[ -z "$str" ]` |
| `-n` | True if string is not empty | `[ -n "$str" ]` |

## File Test Operators

| Operator | Meaning | Example |
|---|---|---|
| `-e` | File exists | `[ -e "script.sh" ]` |
| `-f` | Exists and is a regular file | `[ -f "log.txt" ]` |
| `-d` | Exists and is a directory | `[ -d "/var/log" ]` |
| `-s` | File exists and is not empty | `[ -s "data.csv" ]` |
| `-r` | File has read permissions | `[ -r "config.json" ]` |
| `-w` | File has write permissions | `[ -w "config.json" ]` |
| `-x` | File is executable | `[ -x "run.sh" ]` |

## Logical (Combination) Operators

| Operator | `[ ]` form | `[[ ]]` form | Example |
|---|---|---|---|
| AND | `-a` | `&&` | `[ cond1 ] && [ cond2 ]` |
| OR | `-o` | `\|\|` | `[ cond1 ] \|\| [ cond2 ]` |
| NOT | `!` | `!` | `! [ cond1 ]` |

---

## Script: Time Delay Between Steps

```bash
#!/bin/bash
#
# Exit immediately if a command exits with a non-zero status
set -e

# Helper function to print text and sleep for 3 seconds
run_step() {
    echo "=== $1 ==="
    sleep 3
}

run_step "1. updating a file"
```

---

## Practical Script Example: Age & File Check

```bash
#!/bin/bash
# Define variables
AGE=25
FILE_PATH="./report.txt"

# 1. Numeric and File combination check using [[ ]]
if [[ "$AGE" -ge 18 && -f "$FILE_PATH" ]]; then
    echo "User is an adult and report file exists."
elif [ "$AGE" -lt 18 ]; then
    echo "User is a minor."
else
    echo "Conditions not met."
fi
```

---

## Script: Check & Manage a Service

```bash
#!/bin/bash
# functions
check_services() {
    service=$1
    action=$2

    if pgrep "$service" > /dev/null 2>&1
    then
        echo "$service is running"
    else
        echo "$service is not running"
        sudo systemctl "$action" "$service"
        # sudo systemctl status
    fi
}

check_services "$1" "$2"
```

---

## Script: Conditions (corrected)

> Your original had a few syntax slips — `[` needs a space before and after its arguments, and each `if` needs its own `fi`. Corrected version below:

```bash
#!/bin/bash
# conditions

if [ 3 -gt 4 ]
then
    echo "yes"
else
    echo "no"
fi

# TO CHECK THE FILE
if [ -f /var/test.txt ]
then
    echo "yes exist"
else
    echo "no"
fi

if [ ! -f /var/text.txt ]
then
    echo "not exist"
else
    echo "exist"
fi

# TO SKIP THE OUTPUT OF A COMMAND
if pwd > /dev/null 2>&1
then
    echo "command succeeded"
fi
```

### What was off in the original
| Issue | Fix |
|---|---|
| `[3 -gt 4]` | needs spaces: `[ 3 -gt 4 ]` |
| `[ -f /var/test/txt]` | missing space before `]`, and likely meant `/var/test.txt` (dot, not slash) |
| `[ ! -f /var/text.txt]` | missing space before `]` |
| Missing `fi` statements | every `if` must be closed with a matching `fi` |
