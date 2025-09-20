#!/bin/bash

# UltimatePOS Docker Development Setup Script
# This script sets up the development environment using Docker

set -e

echo "🚀 Setting up UltimatePOS Development Environment..."

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
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Copy environment file
if [ ! -f .env ]; then
    print_status "Copying .env.docker to .env..."
    cp .env.docker .env
else
    print_warning ".env file already exists. Skipping copy."
fi

# Create storage directories
print_status "Creating storage directories..."
mkdir -p storage/app/public
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Set permissions
print_status "Setting proper permissions..."
chmod -R 755 storage
chmod -R 755 bootstrap/cache

# Build and start containers
print_status "Building and starting Docker containers..."
docker-compose up -d --build

# Wait for MySQL to be ready
print_status "Waiting for MySQL to be ready..."
until docker-compose exec mysql mysqladmin ping -h"localhost" --silent; do
    echo -n "."
    sleep 1
done
echo ""

# Install composer dependencies
print_status "Installing Composer dependencies..."
docker-compose exec app composer install

# Build frontend assets
print_status "Building frontend assets..."
docker-compose exec app npm run build

# Generate application key
print_status "Generating application key..."
docker-compose exec app php artisan key:generate

# Run database migrations
print_status "Running database migrations..."
docker-compose exec app php artisan migrate --force

# Seed the database (optional)
read -p "Do you want to seed the database with sample data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Seeding database..."
    docker-compose exec app php artisan db:seed
fi

# Create storage link
print_status "Creating storage symbolic link..."
docker-compose exec app php artisan storage:link

# Clear and cache config
print_status "Optimizing application..."
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan view:clear
docker-compose exec app php artisan config:cache

print_status "✅ Setup completed successfully!"
echo ""
echo "🌐 Your UltimatePOS application is now running at:"
echo "   - Application: http://localhost:8080"
echo "   - phpMyAdmin: http://localhost:8081"
echo "   - MailHog: http://localhost:8025"
echo "   - Redis Commander: http://localhost:8082"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker-compose logs -f app"
echo "   - Stop containers: docker-compose down"
echo "   - Restart containers: docker-compose restart"
echo "   - Access app container: docker-compose exec app bash"
echo ""
print_status "Happy coding! 🎉"