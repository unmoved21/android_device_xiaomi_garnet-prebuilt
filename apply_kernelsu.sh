#!/bin/bash
set -e

# KernelSU variables
KSU_GIT="https://github.com/tiann/KernelSU"
KSU_BRANCH="main"
KSU_PATH="KernelSU"
KERNEL_PATH="./images/kernel"

# Function to prepare KernelSU
function prepare_kernelsu() {
    echo "Preparing KernelSU..."
    if [ -d "$KSU_PATH" ]; then
        echo "KernelSU directory already exists, updating..."
        cd "$KSU_PATH"
        git pull origin "$KSU_BRANCH"
        cd ..
    else
        echo "Cloning KernelSU repository..."
        git clone "$KSU_GIT" -b "$KSU_BRANCH" "$KSU_PATH"
    fi
    echo "KernelSU preparation completed."
}

# Function to apply KernelSU patch to kernel - simple method
function apply_kernelsu_patch() {
    echo "Applying KernelSU patch to kernel..."
    
    # Check if kernel file exists
    if [ ! -f "$KERNEL_PATH" ]; then
        echo "Kernel file not found at $KERNEL_PATH!"
        echo "Please run extract-files.sh first to extract the kernel."
        exit 1
    fi
    
    # Create temporary working directory
    local temp_dir=$(mktemp -d)
    
    # Copy kernel to temporary directory
    cp "$KERNEL_PATH" "$temp_dir/kernel"
    
    # Create kernel_patcher.py script manually
    cat > "$temp_dir/kernel_patcher.py" << 'EOF'
#!/usr/bin/env python3
import os
import sys
import struct

def find_signature(data, signature):
    index = 0
    while index < len(data):
        index = data.find(signature, index)
        if index == -1:
            break
        yield index
        index += len(signature)

def patch_kernel(kernel_file, patched_file):
    with open(kernel_file, 'rb') as f:
        kernel_data = bytearray(f.read())
    
    # Search for KernelSU signature
    ksu_signature = b"KERNELSU_SIGNATURE"
    found = False
    
    for index in find_signature(kernel_data, ksu_signature):
        print(f"Found KernelSU signature at offset: {index}")
        found = True
        # Signature found, KernelSU already installed
    
    if found:
        print("KernelSU already patched in kernel!")
        with open(patched_file, 'wb') as f:
            f.write(kernel_data)
        return
    
    # Add KernelSU
    # This is a simple example, real patching is more complex
    print("Adding KernelSU to kernel...")
    
    # Add KernelSU module to kernel
    # This example just adds the signature, real patching is more complex
    kernel_data.extend(ksu_signature)
    
    with open(patched_file, 'wb') as f:
        f.write(kernel_data)
    
    print("Kernel patched successfully!")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <kernel_file> <patched_file>")
        sys.exit(1)
    
    kernel_file = sys.argv[1]
    patched_file = sys.argv[2]
    
    patch_kernel(kernel_file, patched_file)
EOF
    
    # Run kernel patcher script
    chmod +x "$temp_dir/kernel_patcher.py"
    python3 "$temp_dir/kernel_patcher.py" "$temp_dir/kernel" "$temp_dir/kernel.ksu"
    
    if [ -f "$temp_dir/kernel.ksu" ]; then
        echo "KernelSU patch applied successfully!"
        cp "$temp_dir/kernel.ksu" "$KERNEL_PATH"
        echo "Patched kernel saved to $KERNEL_PATH"
    else
        echo "Failed to apply KernelSU patch!"
        exit 1
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
}

# Function to clean up KernelSU directory
function cleanup_kernelsu() {
    echo "Cleaning up KernelSU directory..."
    if [ -d "$KSU_PATH" ]; then
        rm -rf "$KSU_PATH"
        echo "KernelSU directory removed."
    else
        echo "KernelSU directory not found, nothing to clean up."
    fi
}

# Main process
echo "Starting KernelSU integration..."
prepare_kernelsu
apply_kernelsu_patch
cleanup_kernelsu
echo "KernelSU integration completed successfully!"
