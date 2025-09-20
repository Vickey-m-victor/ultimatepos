#!/bin/bash

# UltimatePOS Docker Production Setup Script

set -e

echo "🏭 Setting up UltimatePOS Production Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if production environment file exists
if [ ! -f .env.prod ]; then
    print_error ".env.prod file not found. Please copy .env.prod.example to .env.prod and configure it."
    exit 1
fi

# Copy production environment
print_status "Using production environment configuration..."
cp .env.prod .env

# Create necessary directories
print_status "Creating production directories..."
mkdir -p storage/app/public
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Set strict permissions for production
print_status "Setting production permissions..."
chmod -R 750 storage
chmod -R 750 bootstrap/cache
chmod 600 .env

# Build production containers
print_status "Building production containers..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services
print_status "Waiting for services to be ready..."
sleep 30

# Install dependencies and optimize
print_status "Installing production dependencies..."
docker-compose -f docker-compose.prod.yml exec app composer install --no-dev --optimize-autoloader

# Run migrations
print_status "Running database migrations..."
docker-compose -f docker-compose.prod.yml exec app php artisan migrate --force

# Create storage link
print_status "Creating storage symbolic link..."
docker-compose -f docker-compose.prod.yml exec app php artisan storage:link

# Optimize for production
print_status "Optimizing for production..."
docker-compose -f docker-compose.prod.yml exec app php artisan config:cache
docker-compose -f docker-compose.prod.yml exec app php artisan route:cache
docker-compose -f docker-compose.prod.yml exec app php artisan view:cache

print_status "✅ Production setup completed!"
echo ""
echo "🌐 Your UltimatePOS application is now running at:"
echo "   - Application: http://localhost (port 80)"
echo ""
echo "⚠️  Important production notes:"
echo "   - Make sure to configure your reverse proxy (nginx/apache)"
echo "   - Set up SSL certificates"
echo "   - Configure regular backups"
echo "   - Monitor logs: docker-compose -f docker-compose.prod.yml logs -f"
echo ""
print_status "Production deployment successful! 🎉"