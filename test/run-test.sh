#!/bin/bash
# run-test.sh

# Go to the directory where the docker-compose.yml is located
cd "$(dirname "$0")"

# Build and start the container
docker compose up -d --build

# Connect to the container
docker compose exec dotfiles-test bash

# When exiting the container, stop it, remove containers, networks, ALL images, orphans, AND named volumes
docker compose down --rmi all --volumes --remove-orphans