# UltimatePOS Google Cloud Deployment Guide

This guide walks you through deploying UltimatePOS on Google Cloud VM.

## Prerequisites

- Google Cloud account with VM instance created
- SSH access to the VM
- Domain name (optional but recommended for SSL)

## Step 1: Connect to Your VM

```bash
gcloud compute ssh --zone "us-central1-a" "staging-server" --project "crackit-cloud"
```

## Step 2: Initial VM Setup

Run the VM setup script to install Docker and dependencies:

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/ultimatepos/main/scripts/setup-vm.sh | bash

# OR if you have the files locally, upload and run:
chmod +x scripts/setup-vm.sh
./scripts/setup-vm.sh
```

**Important:** Reboot the VM after this step:
```bash
sudo reboot
```

## Step 3: Upload Application Files

After reboot, reconnect and upload your application:

### Option A: Using Git (Recommended)
```bash
cd /var/www/html
sudo rm -f index.nginx-debian.html  # Remove default nginx page
sudo git clone https://github.com/your-repo/ultimatepos.git .
sudo chown -R $USER:$USER /var/www/html
```

### Option B: Using SCP from your local machine
```bash
# From your local machine
gcloud compute scp --recurse /path/to/UltimatePOS-CodeBase-V6.8/* staging-server:/var/www/html --zone="us-central1-a" --project="crackit-cloud"
```

## Step 4: Configure Environment Variables

```bash
cd /var/www/html

# Copy the production environment template
cp .env.production.example .env.production

# Edit the environment file
nano .env.production
```

**Required configurations to update in `.env.production`:**

1. **Generate Application Key:**
   ```bash
   # Generate a new Laravel application key
   docker run --rm -v $(pwd):/var/www/html php:8.1-cli php -r "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"
   ```

2. **Database Passwords:**
   ```env
   DB_PASSWORD=your_strong_database_password_here
   DB_ROOT_PASSWORD=your_strong_root_password_here
   ```

3. **Redis Password:**
   ```env
   REDIS_PASSWORD=your_strong_redis_password_here
   ```

4. **Application URL:**
   ```env
   APP_URL=https://your-domain.com
   # OR if using IP: APP_URL=http://YOUR_VM_IP
   ```

5. **Mail Configuration (if needed):**
   ```env
   MAIL_MAILER=smtp
   MAIL_HOST=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=your-app-password
   MAIL_ENCRYPTION=tls
   ```

## Step 5: Deploy the Application

### Without Domain (IP-based access):
```bash
./scripts/deploy-app.sh
```

### With Domain (includes SSL setup):
```bash
./scripts/deploy-app.sh your-domain.com
```

## Step 6: Configure Google Cloud Firewall

Allow HTTP and HTTPS traffic:

```bash
# Allow HTTP (port 80)
gcloud compute firewall-rules create allow-http --allow tcp:80 --source-ranges 0.0.0.0/0 --description "Allow HTTP"

# Allow HTTPS (port 443)
gcloud compute firewall-rules create allow-https --allow tcp:443 --source-ranges 0.0.0.0/0 --description "Allow HTTPS"
```

## Step 7: Access Your Application

- **With Domain:** `https://your-domain.com`
- **With IP:** `http://YOUR_VM_EXTERNAL_IP`

Get your VM's external IP:
```bash
gcloud compute instances describe staging-server --zone=us-central1-a --project=crackit-cloud --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

## Post-Deployment Tasks

### 1. Complete Application Setup
- Access your application URL
- Complete the initial setup wizard
- Change default admin credentials

### 2. Monitor Application
```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Monitor system resources
htop
df -h
```

### 3. Backup Setup
```bash
# Create backup script
sudo crontab -e

# Add daily backup (example)
0 2 * * * docker-compose -f /opt/ultimatepos/docker-compose.prod.yml exec -T mysql mysqldump -u root -p$DB_ROOT_PASSWORD ultimatepos_prod > /opt/backups/db_$(date +\%Y\%m\%d).sql
```

### 4. Security Hardening
```bash
# Update packages regularly
sudo apt update && sudo apt upgrade -y

# Monitor failed login attempts
sudo fail2ban-client status

# Check firewall status
sudo ufw status

# Monitor logs
sudo tail -f /var/log/auth.log
```

## Troubleshooting

### Container Issues
```bash
# Restart all containers
docker-compose -f docker-compose.prod.yml restart

# Rebuild if needed
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Database Issues
```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs mysql

# Connect to database
docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p
```

### SSL Issues
```bash
# Renew SSL certificate
sudo certbot renew

# Check certificate status
sudo certbot certificates
```

### Performance Monitoring
```bash
# Monitor Docker stats
docker stats

# Check disk usage
docker system df

# Clean up unused images
docker system prune -a
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `docker-compose -f docker-compose.prod.yml ps` | Check container status |
| `docker-compose -f docker-compose.prod.yml logs -f app` | View application logs |
| `docker-compose -f docker-compose.prod.yml exec app php artisan migrate` | Run migrations |
| `docker-compose -f docker-compose.prod.yml exec app php artisan cache:clear` | Clear cache |
| `docker-compose -f docker-compose.prod.yml down && docker-compose -f docker-compose.prod.yml up -d` | Restart application |

## Support

For issues or questions:
1. Check the application logs
2. Review this deployment guide
3. Check the official UltimatePOS documentation
4. Ensure all environment variables are correctly set