#!/bin/bash

# UltimatePOS Application Deployment Script
# Run this after the VM setup is complete

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
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

APP_DIR="/var/www/html"
DOMAIN=${1:-""}

print_header "🚀 Starting UltimatePOS application deployment..."

# Check if .env.production exists
if [ ! -f "$APP_DIR/.env.production" ]; then
    print_error ".env.production file not found!"
    print_warning "Please create .env.production file based on .env.production.example"
    print_warning "Update the following required values:"
    echo "  - APP_KEY (generate with: docker run --rm ultimatepos-app php artisan key:generate --show)"
    echo "  - DB_PASSWORD (strong database password)"
    echo "  - DB_ROOT_PASSWORD (strong root password)"
    echo "  - REDIS_PASSWORD (strong redis password)"
    echo "  - APP_URL (your domain URL)"
    echo "  - Mail configuration"
    exit 1
fi

# Load environment variables
export $(cat $APP_DIR/.env.production | grep -v '^#' | xargs)

print_status "Building Docker images..."
cd $APP_DIR
docker-compose -f docker-compose.prod.yml build

print_status "Starting application containers..."
docker-compose -f docker-compose.prod.yml up -d

print_status "Waiting for database to be ready..."
sleep 30

print_status "Running Laravel migrations and setup..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan migrate --force
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:cache

print_status "Setting up storage permissions..."
docker-compose -f docker-compose.prod.yml exec -T app chown -R www-data:www-data /var/www/html/storage
docker-compose -f docker-compose.prod.yml exec -T app chmod -R 755 /var/www/html/storage

# Setup nginx reverse proxy if domain is provided
if [ ! -z "$DOMAIN" ]; then
    print_status "Setting up Nginx reverse proxy for domain: $DOMAIN"
    
    # Create nginx site configuration
    sudo tee /etc/nginx/sites-available/ultimatepos > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOF

    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/ultimatepos /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        print_status "Nginx configured successfully"
        
        # Setup SSL with Let's Encrypt
        print_status "Setting up SSL certificate with Let's Encrypt..."
        sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
        
        if [ $? -eq 0 ]; then
            print_status "SSL certificate installed successfully"
        else
            print_warning "SSL certificate installation failed. You can run it manually later:"
            print_warning "sudo certbot --nginx -d $DOMAIN"
        fi
    else
        print_error "Nginx configuration test failed"
    fi
fi

print_status "✅ Deployment completed successfully!"

echo ""
echo "🎉 UltimatePOS is now running!"
echo ""
echo "📊 Application Status:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "🔗 Access URLs:"
if [ ! -z "$DOMAIN" ]; then
    echo "  🌐 Application: https://$DOMAIN"
    echo "  🌐 HTTP: http://$DOMAIN (redirects to HTTPS)"
else
    echo "  🌐 Application: http://$(curl -s ifconfig.me):80"
fi

echo ""
echo "📋 Useful Commands:"
echo "  📊 Check status: docker-compose -f docker-compose.prod.yml ps"
echo "  📜 View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  🔄 Restart: docker-compose -f docker-compose.prod.yml restart"
echo "  🛑 Stop: docker-compose -f docker-compose.prod.yml down"
echo "  🔧 Laravel commands: docker-compose -f docker-compose.prod.yml exec app php artisan [command]"

echo ""
print_warning "🔒 Security Reminders:"
echo "  - Change default admin password after first login"
echo "  - Review firewall settings: sudo ufw status"
echo "  - Monitor logs regularly"
echo "  - Keep system updated: sudo apt update && sudo apt upgrade"