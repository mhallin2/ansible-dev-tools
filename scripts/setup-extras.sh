#!/bin/bash

# Install required packages
echo "Installing packages: podman, podman-docker, wget, bind-utils..."
dnf -y install podman podman-docker wget bind-utils ping || true
echo "✅ Extra packages has been installed successfully!"

# Create MyNotes workspace structure ( for creating notes directly within VS Code)
echo "Setting up MyNotes workspace..."
mkdir -p /home/runner/github/MyNotes
echo "✅ MyNotes workspace setup completed successfully!"
