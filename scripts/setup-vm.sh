#!/bin/bash

# UltimatePOS Google Cloud Deployment Script
# This script sets up and deploys UltimatePOS on a Google Cloud VM

set -e

echo "🚀 Starting UltimatePOS deployment on Google Cloud VM..."

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed successfully"
else
    print_status "Docker already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully"
else
    print_status "Docker Compose already installed"
fi

# Install other necessary packages
print_status "Installing additional packages..."
sudo apt-get install -y git curl wget unzip nginx certbot python3-certbot-nginx ufw

# Configure firewall
print_status "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
echo "y" | sudo ufw enable

# Setup application directory
APP_DIR="/var/www/html"
print_status "Setting up application directory at $APP_DIR..."
sudo chown $USER:$USER $APP_DIR
sudo chmod 755 $APP_DIR

print_status "✅ VM setup completed successfully!"
print_warning "Please reboot the system to ensure Docker permissions take effect:"
print_warning "sudo reboot"
print_warning ""
print_warning "After reboot, run the application deployment script."

echo ""
echo "🔧 Next steps:"
echo "1. Reboot the VM: sudo reboot"
echo "2. Upload your application files to $APP_DIR"
echo "3. Create .env.production file with your settings"
echo "4. Run the application deployment script"