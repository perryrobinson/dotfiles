#!/bin/bash
# run-test.sh

# Go to the directory where the docker-compose.yml is located
cd "$(dirname "$0")"

# Build and start the container
docker compose up -d --build

# Connect to the container and make scripts executable and cd into dotfiles directory
docker compose exec dotfiles-test bash -c '
    cd ~/dotfiles
    chmod +x install.sh
    chmod +x tools/*.sh
    ./install.sh
'

# When exiting the container, stop it, remove containers, networks, ALL images, orphans, AND named volumes
docker compose down --rmi all --volumes --remove-orphans