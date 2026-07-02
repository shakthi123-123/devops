#!/bin/bash


usage=`df -h | grep "C:" | awk '{print $5}' | sed 's|%||g '`
echo "current usage of disk /: $usage%"

if [ $usage -lt 60 ]
then
	echo "Disk usage is normal: $usage%"
	
elif [ $usage -lt 80 ]
then 
	echo "Disk usage is warnimg: $usage%"
elif [ $usage -lt 90 ]
then
	echo "Disk usage is critical: $usage%"
	echo "Take Immediate Action"

else
        echo "Disk usage is ceitical: $usage%"
	echo "Take Immediate Action"
	
fi
