#!/bin/bash

LOG_FILE="/var/log/docker-compose-restart.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

touch "$LOG_FILE"

log_message "Starting Docker Compose restart process"

log_message "Bringing down Docker Compose services"
docker compose -f infernet-container-starter/deploy/docker-compose.yaml down
if [ $? -eq 0 ]; then
    log_message "Successfully brought down all services"
else
    log_message "Error bringing down services"
    exit 1
fi

sleep 10

log_message "Bringing up Docker Compose services"
docker compose -f infernet-container-starter/deploy/docker-compose.yaml up -d
if [ $? -eq 0 ]; then
    log_message "Successfully brought up all services"
else
    log_message "Error bringing up services"
    exit 1
fi

log_message "Docker Compose restart process completed"