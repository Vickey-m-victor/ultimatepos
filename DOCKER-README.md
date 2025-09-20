# UltimatePOS Docker Setup

This repository includes a complete Docker containerization setup for UltimatePOS, a comprehensive Laravel-based Point of Sale system.

## 🚀 Quick Start

### Development Environment

1. **Clone and navigate to the project:**
   ```bash
   cd UltimatePOS-CodeBase-V6.8
   ```

2. **Run the automated setup:**
   ```bash
   ./scripts/setup-dev.sh
   ```

3. **Access your application:**
   - **UltimatePOS App**: http://localhost:8080
   - **phpMyAdmin**: http://localhost:8081
   - **MailHog (Email Testing)**: http://localhost:8025
   - **Redis Commander**: http://localhost:8082

### Production Environment

1. **Configure production environment:**
   ```bash
   cp .env.prod.example .env.prod
   # Edit .env.prod with your production settings
   ```

2. **Deploy to production:**
   ```bash
   ./scripts/setup-prod.sh
   ```

## 📋 Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 4GB RAM available for containers
- 10GB+ free disk space

## 🏗️ Architecture

### Services

| Service | Description | Port | Purpose |
|---------|-------------|------|---------|
| **app** | Laravel application with Nginx + PHP-FPM | 8080 | Main application |
| **mysql** | MySQL 8.0 database | 3306 | Data storage |
| **redis** | Redis cache and session store | 6379 | Caching & sessions |
| **phpmyadmin** | Database management interface | 8081 | Database admin |
| **mailhog** | Email testing tool | 8025 | Email debugging |
| **redis-commander** | Redis management interface | 8082 | Redis admin |

### Container Features

- **Multi-stage Dockerfile** for optimized production builds
- **PHP 8.1** with all required extensions
- **Nginx** web server with optimized configuration
- **Supervisor** for process management
- **Laravel queue workers** for background jobs
- **Laravel scheduler** for cron jobs
- **Xdebug** support for development

## 🛠️ Development Workflow

### Using the Helper Script

The `scripts/docker-helper.sh` script provides convenient commands:

```bash
# Start containers
./scripts/docker-helper.sh start

# View application logs
./scripts/docker-helper.sh logs

# Access application shell
./scripts/docker-helper.sh shell

# Run database migrations
./scripts/docker-helper.sh migrate

# Seed database with sample data
./scripts/docker-helper.sh seed

# Optimize application (clear caches)
./scripts/docker-helper.sh optimize

# Create database backup
./scripts/docker-helper.sh backup

# Show all available commands
./scripts/docker-helper.sh help
```

### Manual Docker Commands

```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f app

# Execute commands in containers
docker-compose exec app php artisan migrate
docker-compose exec app composer install
docker-compose exec mysql mysql -u ultimatepos -p

# Stop all services
docker-compose down
```

## 🔧 Configuration

### Environment Variables

The setup includes three environment configurations:

1. **`.env.docker`** - Development configuration with Docker services
2. **`.env.prod.example`** - Production template (copy to `.env.prod`)
3. **`.env.example`** - Original Laravel environment template

Key Docker-specific settings:

```env
# Database (points to Docker MySQL container)
DB_HOST=mysql
DB_DATABASE=ultimatepos
DB_USERNAME=ultimatepos
DB_PASSWORD=ultimatepos_password

# Redis (points to Docker Redis container)
REDIS_HOST=redis
REDIS_PASSWORD=ultimatepos_redis_password

# Mail (points to MailHog for development)
MAIL_HOST=mailhog
MAIL_PORT=1025
```

### Customizing PHP Configuration

Edit `docker/php/php.ini` to customize PHP settings:

```ini
memory_limit = 512M
max_execution_time = 300
upload_max_filesize = 100M
post_max_size = 100M
```

### Customizing Nginx Configuration

Edit `docker/nginx/default.conf` for web server settings:

```nginx
client_max_body_size 100M;
fastcgi_read_timeout 300;
```

## 📦 Production Deployment

### 1. Environment Setup

```bash
# Copy and configure production environment
cp .env.prod.example .env.prod

# Essential production settings to configure:
# - APP_KEY (generate with: php artisan key:generate)
# - DB_PASSWORD (strong database password)
# - REDIS_PASSWORD (strong Redis password)
# - MAIL_* (production SMTP settings)
# - Payment gateway credentials
# - License codes
```

### 2. Security Considerations

- Change all default passwords
- Use strong, randomly generated passwords
- Configure SSL/TLS certificates
- Set up proper firewall rules
- Enable regular automated backups
- Monitor logs and set up alerting

### 3. Reverse Proxy Setup

For production, use a reverse proxy (nginx/apache) in front of Docker:

```nginx
# Example nginx configuration
server {
    listen 80;
    server_name yourdomain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Permission Issues**
   ```bash
   sudo chown -R $USER:$USER storage bootstrap/cache
   chmod -R 755 storage bootstrap/cache
   ```

2. **Database Connection Issues**
   ```bash
   # Check if MySQL container is running
   docker-compose ps mysql
   
   # Check MySQL logs
   docker-compose logs mysql
   ```

3. **Composer Dependencies**
   ```bash
   # Reinstall dependencies
   docker-compose exec app composer install --no-cache
   ```

4. **Clear All Caches**
   ```bash
   docker-compose exec app php artisan optimize:clear
   ```

### Performance Optimization

1. **Enable OpCache** (already configured in `docker/php/php.ini`)
2. **Use Redis for sessions and cache** (configured by default)
3. **Optimize Composer autoloader**:
   ```bash
   docker-compose exec app composer dump-autoload --optimize
   ```

## 📊 Monitoring

### Health Checks

The application container includes health checks:

```bash
# Check container health
docker-compose ps

# View health check logs
docker inspect ultimatepos_app | grep -A 10 '"Health"'
```

### Log Management

```bash
# Application logs
docker-compose logs -f app

# Database logs
docker-compose logs -f mysql

# All services logs
docker-compose logs -f
```

## 🔄 Backup and Recovery

### Database Backup

```bash
# Automated backup using helper script
./scripts/docker-helper.sh backup

# Manual backup
docker-compose exec mysql mysqldump -u ultimatepos -pultimatepos_password ultimatepos > backup.sql
```

### Database Restore

```bash
# Using helper script
./scripts/docker-helper.sh restore backup.sql

# Manual restore
docker-compose exec -T mysql mysql -u ultimatepos -pultimatepos_password ultimatepos < backup.sql
```

### File Backup

Important directories to backup:
- `storage/app/` - User uploads and files
- `storage/logs/` - Application logs
- `.env` - Environment configuration

## 🚀 Scaling

### Horizontal Scaling

For high-traffic deployments:

1. **Load Balancer**: Use nginx or HAProxy
2. **Multiple App Containers**: Scale the app service
3. **External Database**: Use managed MySQL (RDS, etc.)
4. **External Redis**: Use managed Redis service
5. **File Storage**: Use S3 or similar for uploads

```bash
# Scale app containers
docker-compose up -d --scale app=3
```

## 📝 Additional Notes

- **Queue Workers**: Configured to process background jobs
- **Task Scheduler**: Laravel scheduler runs automatically
- **File Permissions**: Properly configured for Laravel
- **Xdebug**: Available in development for debugging
- **Hot Reload**: Code changes reflect immediately in development

## 🤝 Contributing

When contributing to the Docker setup:

1. Test changes in both development and production modes
2. Update documentation for any configuration changes
3. Ensure backwards compatibility
4. Test backup and restore procedures

## 📞 Support

For Docker-specific issues:
1. Check this README first
2. Review container logs: `docker-compose logs`
3. Verify environment configuration
4. Check Docker and Docker Compose versions

---

**Happy containerizing! 🐳**