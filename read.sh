#!/bin/bash -x
# Read Command
#


#1. Read a line of text (Basic)
#Ask the user for input
read -p "Enter your name: " user_name #Use the -p flag to display a prompt message on the screen before waiting for input

# Use the variable
echo "Hello, $user_name!"

#2. Read a single keystroke (Y/N Confirmation)
read -p "Do you want to install Docker? (y/n): " -n 1 choice  #Use the -n 1 flag to limit the input to exactly one character.
echo "" # Prints a new line

if [ "$choice" = "y" ] || [ "$choice" = "Y" ] 
then
	    echo "Starting installation..."
    else
	        echo "Installation cancelled."
fi


#3. Read secrets silently (Passwords)

read -p "Enter your sudo password: " -s my_password #-s flag to hide characters as they are typed. This is crucial for passwords or API tokens.
echo "" # Prints a new line

# Use the hidden password safely
# echo "Password saved to memory."

#4. Read an interactive command and run it
read -p "Type a command to run (e.g., 'ls -la' or 'df -h'): " user_cmd

echo "Running: $user_cmd..."
eval "$user_cmd" # 'eval' executes the string as a real command

#5. Set a timeout limit

# Wait 5 seconds for a response
if read -t 5 -p "Press Enter to continue (Timeout in 5s)..." ; #-t flag followed by seconds. If the user does not type anything before the timer ends 
then
    echo "Moving to next step manually."
    else
        echo ""
	echo "Timed out! Moving to next step automatically."
fi


