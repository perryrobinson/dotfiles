#!/bin/bash
# run-test.sh

# Build and start the container
docker-compose up -d --build

# Connect to the container
docker-compose exec dotfiles-test bash

# When exiting the container, stop it
docker-compose down