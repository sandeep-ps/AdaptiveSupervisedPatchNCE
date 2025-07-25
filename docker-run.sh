#!/bin/bash

# Docker helper script for AdaptiveSupervisedPatchNCE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
}

# Check if NVIDIA Docker runtime is available
check_nvidia_docker() {
    if ! which nvidia-container-toolkit > /dev/null 2>&1; then
        print_warning "NVIDIA Container Toolkit not detected. GPU support may not work."
        print_warning "Make sure you have nvidia-container-toolkit installed."
    fi
}

# Build the Docker image
build_image() {
    print_status "Building Docker image..."
    docker build -t asp-training .
    print_status "Docker image built successfully!"
}

# Run training
run_training() {
    local gpu_id=${1:-0}
    print_status "Starting training with GPU $gpu_id..."
    
    docker run --rm -it \
        --gpus all \
        --shm-size=8g \
        -e INTEL_JIT_PROVIDER=0 \
        -v "$(pwd)/datasets:/workspace/datasets" \
        -v "$(pwd)/checkpoints:/workspace/checkpoints" \
        -v "$(pwd)/results:/workspace/results" \
        -v "$(pwd)/logs:/workspace/logs" \
        -p 8097:8097 \
        -p 6006:6006 \
        asp-training \
        conda run -n ASP python -m experiments mist train $gpu_id
}

# Run testing
run_testing() {
    local dataroot=${1:-"./datasets/your_dataset"}
    local name=${2:-"your_experiment"}
    local model=${3:-"your_model"}
    
    print_status "Starting testing..."
    print_status "Dataset: $dataroot"
    print_status "Experiment name: $name"
    print_status "Model: $model"
    
    docker run --rm -it \
        --gpus all \
        --shm-size=8g \
        -v "$(pwd)/datasets:/workspace/datasets" \
        -v "$(pwd)/checkpoints:/workspace/checkpoints" \
        -v "$(pwd)/results:/workspace/results" \
        -p 8097:8097 \
        asp-training \
        conda run -n ASP python test.py --dataroot $dataroot --name $name --model $model
}

# Interactive shell
run_shell() {
    print_status "Starting interactive shell..."
    docker run --rm -it \
        --gpus all \
        --shm-size=8g \
        -v "$(pwd)/datasets:/workspace/datasets" \
        -v "$(pwd)/checkpoints:/workspace/checkpoints" \
        -v "$(pwd)/results:/workspace/results" \
        -v "$(pwd)/logs:/workspace/logs" \
        -p 8097:8097 \
        -p 6006:6006 \
        asp-training \
        /bin/bash
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build                    Build the Docker image"
    echo "  train [GPU_ID]           Run training (default GPU_ID=0)"
    echo "  test [DATAROOT] [NAME] [MODEL]  Run testing"
    echo "  shell                    Start interactive shell"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 train 0"
    echo "  $0 test ./datasets/horse2zebra horse2zebra_pretrained cycle_gan"
    echo "  $0 shell"
}

# Main script logic
main() {
    check_docker
    check_nvidia_docker
    
    case "${1:-help}" in
        "build")
            build_image
            ;;
        "train")
            run_training "${2:-0}"
            ;;
        "test")
            run_testing "${2:-./datasets/your_dataset}" "${3:-your_experiment}" "${4:-your_model}"
            ;;
        "shell")
            run_shell
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run main function with all arguments
main "$@" 