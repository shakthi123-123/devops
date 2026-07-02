Crucial Syntax Rules to Remember

• Spaces are mandatory: You must put spaces around the brackets and operators. For example,
   will fail completely; it must be written as .
• Quote your variables: Always wrap your string variables in double quotes () when using single brackets
   to prevent syntax crashes if the variable happens to be empty. [6, 22]

nano new_file.sh (Create the file)
chmod +x new_file.sh (Make it executable)
./new_file.sh (Run the script)
  or
sh new_file.sh (Run the script without executable)


sudo systemctl start 'app name '
sudo systemctl status 'app name'
ps -ef |grep -i 'app name'


Numeric Comparison Operators

-eq  Equal to                  [ "$a" -eq "$b" ]
-ne  Not equal to              [ "$a" -ne "$b" ]
-gt  Greater than              [ "$a" -gt "$b" ]
-ge  Greater than or equal to  [ "$a" -ge "$b" ]
-lt  Less than                 [ "$a" -lt "$b" ]
-le  Less than or equal to     [ "$a" -le "$b" ]

String Comparison Operators

=or == Equal to                     [ "$str1" = "$str2" ]
!=     Not equal to                 [ "$str1" != "$str2" ]
-z     True if string is empty      [ -z "$str" ]
-n     True if string is not empty  [ -n "$str" ]

File Test Operators

-e  File exists                   [ -e "script.sh" ]
-f  Exists and is a regular file  [ -f "log.txt" ]
-d  Exists and is a directory     [ -d "/var/log" ]
-s  File exists and is not empty  [ -s "data.csv" ]
-r  File has read permissions     [ -r "config.json" ]
-w  File has write permissions    [ -w "config.json" ]
-x  File is executable            [ -x "run.sh" ]

Logical (Combination) Operators

AND   -a  &&     [ cond1 ] && [ cond2 ]
OR    -o  ||     [ cond1 ] || [ cond2 ]

NOT    !  !    ! [ cond1 ]


                                               SCRIPT FOR TIME DILAY
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




                                               Practical Script Example

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


#!/bin/bash
#functions

check_services() {

             service=$1
             action=$2

if pgrep $service > /dev/null 2>&1
then
	echo "$service is running"
else
        echo "$service is not running"
	sudo systemctl $action $service
	#sudo systemctl status
fi
}

check_services $1 $2


#!/bin/bash
#conditions
if [3 -gt 4]
then
       echo "yes"
else
       echo "no"

if [ -f /var/test/txt]  (TO CHECK THE FILE)
then
    echo "yes exist"
else
    echo "no"

if [ ! -f /var/text.txt] 
then
    echo "not exist" 
else
    echo "exist"

if pwd > /dev/null 2>&1 (TO SKIP THE OUTPUT COMMAND) 

