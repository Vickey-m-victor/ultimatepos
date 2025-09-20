#!/bin/bash

# Direct deployment script for VM with existing /var/www/html structure
# Run this script directly on your Google Cloud VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

print_header "🚀 Setting up UltimatePOS on Google Cloud VM..."

# Update system
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

# Install additional packages
print_status "Installing additional packages..."
sudo apt-get install -y git curl wget unzip nginx certbot python3-certbot-nginx ufw

# Configure firewall
print_status "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
echo "y" | sudo ufw enable

# Set up /var/www/html directory
print_status "Setting up application directory..."
sudo chown -R $USER:$USER /var/www/html
sudo chmod -R 755 /var/www/html

# Remove default nginx page if it exists
if [ -f "/var/www/html/index.nginx-debian.html" ]; then
    sudo rm -f /var/www/html/index.nginx-debian.html
    print_status "Removed default nginx page"
fi

print_status "✅ VM setup completed successfully!"
print_warning "Now upload your UltimatePOS files to /var/www/html"
print_warning ""
print_warning "Upload command from your local machine:"
print_warning "gcloud compute scp --recurse /path/to/UltimatePOS-CodeBase-V6.8/* staging-server:/var/www/html --zone='us-central1-a' --project='crackit-cloud'"
print_warning ""
print_warning "After uploading, run: ./scripts/deploy-app.sh [your-domain.com]"

echo ""
echo "🔧 Next steps:"
echo "1. Upload your application files to /var/www/html"
echo "2. Create .env.production file with your settings"
echo "3. Run: ./scripts/deploy-app.sh [your-domain.com]"