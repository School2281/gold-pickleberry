#!/bin/bash
# /home/pi/deploy-nginx-on-boot.sh

# Determine the home directory based on who's running the script
if [ "$USER" = "root" ]; then
    HOME_DIR="/home/pi"
    LOG_FILE="$HOME_DIR/startup.log"
    REPO_DIR="$HOME_DIR/nginx-server"
else
    HOME_DIR="$HOME"
    LOG_FILE="$HOME_DIR/startup.log"
    REPO_DIR="$HOME_DIR/nginx-server"
fi

echo "=== $(date) ===" >> "$LOG_FILE"
echo "Starting NGINX deployment as user: $USER" >> "$LOG_FILE"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Home directory: $HOME_DIR"
log "Log file: $LOG_FILE"
log "Repo directory: $REPO_DIR"

# 1. Wait for network and services
log "Waiting for network..."
sleep 15

# 2. Check if NGINX is installed
if ! command -v nginx &> /dev/null; then
    log "NGINX not found, installing..."
    apt update >> "$LOG_FILE" 2>&1
    apt install nginx -y >> "$LOG_FILE" 2>&1
fi

# In your script, add this comprehensive fix:
log "Ensuring NGINX runtime directories exist..."

# Create runtime directory (systemd might do this, but we ensure it)
mkdir -p /run/nginx
chown www-data:www-data /run/nginx
chmod 755 /run/nginx

# Also fix log directory
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx

# Fix cache directory
mkdir -p /var/cache/nginx
chown -R www-data:www-data /var/cache/nginx

# Set sticky bit on temp directories if needed
chmod +t /run/nginx 2>/dev/null || true

# 3. Deploy configuration files
if [ -d "$REPO_DIR" ]; then
    log "Found repository at $REPO_DIR"
    
    # Copy main config if exists
    if [ -f "$REPO_DIR/nginx.conf" ]; then
        cp "$REPO_DIR/nginx.conf" /etc/nginx/nginx.conf
        log "Copied nginx.conf"
    fi
    
    # Copy video_server.conf if exists
    if [ -f "$REPO_DIR/video_server.conf" ]; then
        cp "$REPO_DIR/video_server.conf" /etc/nginx/sites-available/video_server
        ln -sf /etc/nginx/sites-available/video_server /etc/nginx/sites-enabled/
        log "Copied video_server.conf"
    fi
    
    # Copy other .conf files
    for conf_file in "$REPO_DIR"/*.conf; do
        if [ -f "$conf_file" ] && [ "$(basename "$conf_file")" != "nginx.conf" ] && [ "$(basename "$conf_file")" != "video_server.conf" ]; then
            cp "$conf_file" /etc/nginx/sites-available/
            log "Copied $(basename "$conf_file")"
        fi
    done
    
    # Enable all site configs
    for site_conf in /etc/nginx/sites-available/*; do
        if [ -f "$site_conf" ]; then
            site_name=$(basename "$site_conf")
            ln -sf "$site_conf" /etc/nginx/sites-enabled/
            log "Enabled site: $site_name"
        fi
    done
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Copy web content
    log "Copying web content..."
    mkdir -p /var/www/html
    
    # Copy index.html
    if [ -f "$REPO_DIR/index.html" ]; then
        cp "$REPO_DIR/index.html" /var/www/html/
        log "Copied index.html"
    fi
    
    # Copy video files
    for i in {1..3}; do
        if [ -f "$REPO_DIR/video$i.mp4" ]; then
            cp "$REPO_DIR/video$i.mp4" /var/www/html/
            log "Copied video$i.mp4"
        fi
    done
    
    # Copy any other files in repo root (CSS, JS, images)
    for file in "$REPO_DIR"/*; do
        if [ -f "$file" ] && [[ "$file" != *.conf ]] && [[ "$(basename "$file")" != video*.mp4 ]] && [ "$(basename "$file")" != "index.html" ]; then
            cp "$file" /var/www/html/
            log "Copied $(basename "$file")"
        fi
    done
    
    # Set permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    log "Set permissions"
    
else
    log "ERROR: Repository directory not found at $REPO_DIR"
fi

# 4. Test and restart NGINX
log "Testing NGINX configuration..."
if nginx -t >> "$LOG_FILE" 2>&1; then
    log "Configuration test passed, restarting NGINX..."
    systemctl restart nginx
    
    # Verify it's running
    if systemctl is-active --quiet nginx; then
        log "✅ NGINX is running successfully"
        
        # Display server info
        IP=$(hostname -I | awk '{print $1}')
        log "Server IP: $IP"
        log "Access at: http://$IP/"
        
        # Create a quick info file
        echo "NGINX Server Information" > "$HOME_DIR/server-info.txt"
        echo "IP Address: $IP" >> "$HOME_DIR/server-info.txt"
        echo "Startup Time: $(date)" >> "$HOME_DIR/server-info.txt"
        echo "Status: Running" >> "$HOME_DIR/server-info.txt"
        echo "Files deployed:" >> "$HOME_DIR/server-info.txt"
        ls -la /var/www/html/ >> "$HOME_DIR/server-info.txt"
        
    else
        log "❌ NGINX failed to start"
        systemctl status nginx >> "$LOG_FILE" 2>&1
    fi
else
    log "❌ NGINX configuration test failed"
fi

log "Deployment script completed at $(date)"
