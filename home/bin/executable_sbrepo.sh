#!/bin/bash

set -e

# Default values
IMAGE="ubuntu:24.04"
CONTAINER_NAME="repo-sandbox-$$"
WORKDIR="/workspace"

usage() {
    echo "Usage: $0 <github-repo> [options]"
    echo ""
    echo "Arguments:"
    echo "  github-repo    GitHub repo URL or owner/repo format"
    echo ""
    echo "Options:"
    echo "  -i, --image    Docker image to use (default: ubuntu:24.04)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/owner/repo"
    echo "  $0 owner/repo"
    echo "  $0 owner/repo -i python:3.11"
    exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    usage
fi

REPO="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Convert owner/repo format to full URL
if [[ ! "$REPO" =~ ^https?:// ]]; then
    REPO="https://github.com/$REPO"
fi

# Extract repo name for the workspace directory
REPO_NAME=$(basename "$REPO" .git)

echo "Starting sandbox container..."
echo "  Image: $IMAGE"
echo "  Repo: $REPO"
echo ""

# Run container with git installed, clone repo, and drop into shell
docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -w "$WORKDIR/$REPO_NAME" \
    "$IMAGE" \
    /bin/bash -c "
        apt-get update -qq && apt-get install -y -qq git > /dev/null 2>&1 || \
        (apk add --no-cache git > /dev/null 2>&1) || \
        (yum install -y git > /dev/null 2>&1) || \
        echo 'Warning: Could not install git, it may already be available'

        mkdir -p $WORKDIR
        cd $WORKDIR
        echo 'Cloning repository...'
        git clone --depth 1 '$REPO'
        cd '$REPO_NAME'
        echo ''
        echo '================================================'
        echo 'Sandbox ready! You are in: $WORKDIR/$REPO_NAME'
        echo 'Type \"exit\" to leave and destroy the container'
        echo '================================================'
        echo ''
        exec /bin/bash
    "

echo "Container destroyed. Your system is clean!"
