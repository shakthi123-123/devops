#!/bin/bash

# Installing Docker
        echo "=========INSTALLING=DOCKER============"
	sleep 4
if sudo apt-get install -y docker.io
then
        echo "=========INSTALLING=COMPLETED========="
else
	echo "============NOT=COMPLETED============="
fi
        echo""

# Starting Docker
        echo "============STARTING=DOCKER============="
	sleep 4
if sudo systemctl start docker && sudo systemctl enable docker
then
	echo "=============DOCKER=RUNNING============"
	echo "===============COMPLETED==============="
fi
        echo ""

# Docker Status
         echo "============DOCKER=STATUS============="
          sleep 3
status_code=$?
if sudo systemctl status docker | cat
then
         echo "===========DOCKER=ACTIVATED==========="

else
         echo "================ERROR================="
fi

run_step "7. 👤 Adding current user to the Docker group..."
sudo apt install util-linux-extra
sudo usermod -aG docker $USER
newgrp docker
echo ""