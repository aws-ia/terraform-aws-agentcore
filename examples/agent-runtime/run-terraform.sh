#!/bin/bash

# This script helps ensure Docker is in the PATH before running Terraform

# Print current Docker status
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "Docker is installed and in PATH: $(which docker)"
    docker --version
else
    echo "Docker not found in PATH. Attempting to locate it..."
fi

# Try to find Docker in common locations
DOCKER_LOCATIONS=(
    "/usr/local/bin/docker"
    "/usr/bin/docker"
    "/opt/homebrew/bin/docker"
    "$HOME/.docker/bin/docker"
    "/Applications/Docker.app/Contents/Resources/bin/docker"
    "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
    "C:\Program Files\Docker\Docker\resources\docker.exe"
)

for location in "${DOCKER_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        echo "Found Docker at: $location"
        echo "Adding to PATH..."
        export PATH="$(dirname "$location"):$PATH"
        break
    fi
done

# Check again if Docker is available
if command -v docker &> /dev/null; then
    echo "Docker is now available: $(which docker)"
    echo "Docker version: $(docker --version)"
else
    echo "ERROR: Docker is still not available in PATH."
    echo "Please install Docker or add it to your PATH manually."
    echo "Common Docker installation locations:"
    echo "  - macOS: /usr/local/bin/docker or /opt/homebrew/bin/docker"
    echo "  - Linux: /usr/bin/docker"
    echo "  - Windows: C:\Program Files\Docker\Docker\resources\bin\docker.exe"
    exit 1
fi

# Check if Docker daemon is running
echo "Checking if Docker daemon is running..."
if docker info &> /dev/null; then
    echo "Docker daemon is running."
else
    echo "ERROR: Docker daemon is not running."
    echo "Please start Docker and try again."
    echo "  - macOS/Windows: Start Docker Desktop application"
    echo "  - Linux: Run 'sudo systemctl start docker'"
    exit 1
fi

# Run Terraform with the specified command
echo "Running Terraform with command: $@"
terraform "$@"
