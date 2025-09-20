#!/bin/bash

# UltimatePOS Docker Helper Script
# Provides common Docker operations for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "UltimatePOS Docker Helper Script"
    echo ""
    echo "Usage: ./docker-helper.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start all containers"
    echo "  stop        Stop all containers"
    echo "  restart     Restart all containers"
    echo "  logs        Show application logs"
    echo "  shell       Access application container shell"
    echo "  mysql       Access MySQL shell"
    echo "  redis       Access Redis CLI"
    echo "  migrate     Run database migrations"
    echo "  seed        Seed the database"
    echo "  fresh       Fresh migration with seeding"
    echo "  optimize    Optimize application (clear/cache)"
    echo "  backup      Create database backup"
    echo "  restore     Restore database from backup"
    echo "  status      Show container status"
    echo "  update      Update containers"
    echo "  clean       Clean up Docker resources"
    echo "  help        Show this help message"
}

case "${1:-help}" in
    "start")
        print_info "Starting containers..."
        docker-compose up -d
        print_success "Containers started!"
        ;;
    
    "stop")
        print_info "Stopping containers..."
        docker-compose down
        print_success "Containers stopped!"
        ;;
    
    "restart")
        print_info "Restarting containers..."
        docker-compose restart
        print_success "Containers restarted!"
        ;;
    
    "logs")
        print_info "Showing application logs..."
        docker-compose logs -f app
        ;;
    
    "shell")
        print_info "Accessing application container..."
        docker-compose exec app bash
        ;;
    
    "mysql")
        print_info "Accessing MySQL shell..."
        docker-compose exec mysql mysql -u ultimatepos -p ultimatepos
        ;;
    
    "redis")
        print_info "Accessing Redis CLI..."
        docker-compose exec redis redis-cli -a ultimatepos_redis_password
        ;;
    
    "migrate")
        print_info "Running database migrations..."
        docker-compose exec app php artisan migrate
        print_success "Migrations completed!"
        ;;
    
    "seed")
        print_info "Seeding database..."
        docker-compose exec app php artisan db:seed
        print_success "Database seeded!"
        ;;
    
    "fresh")
        print_warning "This will destroy all data! Are you sure? (y/N)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Running fresh migration with seeding..."
            docker-compose exec app php artisan migrate:fresh --seed
            print_success "Fresh migration completed!"
        else
            print_info "Operation cancelled."
        fi
        ;;
    
    "optimize")
        print_info "Optimizing application..."
        docker-compose exec app php artisan config:clear
        docker-compose exec app php artisan cache:clear
        docker-compose exec app php artisan view:clear
        docker-compose exec app php artisan config:cache
        print_success "Application optimized!"
        ;;
    
    "backup")
        BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
        print_info "Creating database backup: $BACKUP_FILE"
        docker-compose exec mysql mysqldump -u ultimatepos -pultimatepos_password ultimatepos > "$BACKUP_FILE"
        print_success "Database backup created: $BACKUP_FILE"
        ;;
    
    "restore")
        if [ -z "$2" ]; then
            print_error "Please provide backup file: ./docker-helper.sh restore backup_file.sql"
            exit 1
        fi
        if [ ! -f "$2" ]; then
            print_error "Backup file not found: $2"
            exit 1
        fi
        print_warning "This will replace all data! Are you sure? (y/N)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Restoring database from: $2"
            docker-compose exec -T mysql mysql -u ultimatepos -pultimatepos_password ultimatepos < "$2"
            print_success "Database restored!"
        else
            print_info "Operation cancelled."
        fi
        ;;
    
    "status")
        print_info "Container status:"
        docker-compose ps
        ;;
    
    "update")
        print_info "Updating containers..."
        docker-compose pull
        docker-compose up -d --build
        print_success "Containers updated!"
        ;;
    
    "clean")
        print_warning "This will remove unused Docker resources. Continue? (y/N)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up Docker resources..."
            docker system prune -f
            docker volume prune -f
            print_success "Cleanup completed!"
        else
            print_info "Operation cancelled."
        fi
        ;;
    
    "help"|*)
        show_help
        ;;
esac