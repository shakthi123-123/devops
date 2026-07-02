#!/bin/bash
  
        echo "updating"
	sleep 2
# Updating
if sudo apt-get update 
then
	echo "update completed"
fi
        echo""
       

# Upgrading
        echo "upgrading"
	sleep 2
if sudo apt upgrade 
then
        echo "upgrade completed"
fi
 
       
# Installing Docker
        echo "docker Installing"
	sleep 2
if sudo apt-get install docker -y docker.io
then
	echo "docker install completed"
fi


# Starting docker
        echo "starting docker"
	sleep 2
if sudo systemctl start docker && sudo systemctl enable docker
then
	echo "docker started and running"
	echo "completed"
fi
