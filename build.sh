#!/bin/bash

# Build and Setup Script for Azure Development Environment
# This script builds the Docker image and sets up the development environment

echo "🚀 Setting up Azure Development Environment..."

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to build the custom image
build_image() {
    echo "🔨 Building custom Azure development image..."
    docker build -t terradev:latest .
    
    if [ $? -eq 0 ]; then
        echo "✅ Image built successfully!"
    else
        echo "❌ Failed to build image"
        exit 1
    fi
}

# Function to start the development environment
start_environment() {
    echo "🌟 Starting development environment..."
    docker-compose -f docker.yml up -d azure-dev
    
    if [ $? -eq 0 ]; then
        echo "✅ Environment started successfully!"
        echo "📝 To connect to your container, run:"
        echo "   docker exec -it terradev /bin/bash"
    else
        echo "❌ Failed to start environment"
        exit 1
    fi
}

# Function to show usage instructions
show_usage() {
    echo ""
    echo "📋 Available commands:"
    echo "  ./build.sh build     - Build the Docker image"
    echo "  ./build.sh start     - Start the development environment"
    echo "  ./build.sh connect   - Connect to the running container"
    echo "  ./build.sh stop      - Stop the development environment"
    echo "  ./build.sh clean     - Remove containers and images"
    echo ""
}

# Main script logic
case "${1:-build}" in
    "build")
        check_docker
        build_image
        ;;
    "start")
        check_docker
        start_environment
        ;;
    "connect")
        docker exec -it terradev /bin/bash
        ;;
    "stop")
        echo "🛑 Stopping development environment..."
        docker-compose -f docker.yml down
        ;;
    "clean")
        echo "🧹 Cleaning up containers and images..."
        docker-compose -f docker.yml down --rmi all --volumes
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        echo "❓ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac