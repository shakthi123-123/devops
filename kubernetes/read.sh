#!/bin/bash

# Runs 'date' and stores the current timestamp text into a variable
current_time=$(date)

# Runs 'docker ps' and stores the active container names
active_containers=$(docker ps --format "{{.Names}}")

# Use the stored outputs later in your script
echo "The script started at: $current_time"
echo "Currently running containers: $active_containers"
