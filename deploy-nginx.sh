#!/bin/bash
# /home/pi/deploy-nginx-on-boot.sh

LOG_FILE="/home/pi/startup.log"
REPO_DIR="/home/pi/nginx-server"  # Change to your repo name

echo "=== $(date) ===" >> $LOG_FILE
echo "Starting NGINX deployment..." >> $LOG_FILE

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# 1. Wait for network and services
log "Waiting for network..."
sleep 15

# 2. Check if NGINX is installed
if ! command -v nginx &> /dev/null; then
    log "NGINX not found, installing..."
    sudo apt update
    sudo apt install nginx -y
fi

# 3. Deploy configuration files
if [ -d "$REPO_DIR" ]; then
    log "Found repository at $REPO_DIR"
    
    # Copy main config if exists
    if [ -f "$REPO_DIR/nginx.conf" ]; then
        sudo cp "$REPO_DIR/nginx.conf" /etc/nginx/nginx.conf
        log "Copied nginx.conf"
    fi
    
    # Copy video_server.conf if exists (NEW)
    if [ -f "$REPO_DIR/video_server.conf" ]; then
        sudo cp "$REPO_DIR/video_server.conf" /etc/nginx/sites-available/video_server
        sudo ln -sf /etc/nginx/sites-available/video_server /etc/nginx/sites-enabled/
        log "Copied video_server.conf"
    fi
    
    # Copy other .conf files
    for conf_file in "$REPO_DIR"/*.conf; do
        if [ -f "$conf_file" ] && [ "$(basename "$conf_file")" != "nginx.conf" ] && [ "$(basename "$conf_file")" != "video_server.conf" ]; then
            sudo cp "$conf_file" /etc/nginx/sites-available/
            log "Copied $(basename "$conf_file")"
        fi
    done
    
    # Enable all site configs
    for site_conf in /etc/nginx/sites-available/*; do
        if [ -f "$site_conf" ]; then
            site_name=$(basename "$site_conf")
            sudo ln -sf "$site_conf" /etc/nginx/sites-enabled/
            log "Enabled site: $site_name"
        fi
    done
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Copy web content (handles your index.html and video.mp4)
    log "Copying web content..."
    sudo mkdir -p /var/www/html
    
    # Copy index.html (your single HTML file)
    if [ -f "$REPO_DIR/index.html" ]; then
        sudo cp "$REPO_DIR/index.html" /var/www/html/
        log "Copied index.html"
    fi
    
    # Copy video.mp4
    if [ -f "$REPO_DIR/video1.mp4" ]; then
        sudo cp "$REPO_DIR/video1.mp4" /var/www/html/
        log "Copied video.mp4"
    fi

    if [ -f "$REPO_DIR/video2.mp4" ]; then
        sudo cp "$REPO_DIR/video2.mp4" /var/www/html/
        log "Copied video.mp4"
    fi

    if [ -f "$REPO_DIR/video3.mp4" ]; then
        sudo cp "$REPO_DIR/video3.mp4" /var/www/html/
        log "Copied video.mp4"
    fi
    
    # Copy any other files in repo root (CSS, JS, images)
    for file in "$REPO_DIR"/*; do
        if [ -f "$file" ] && [[ "$file" != *.conf ]] && [ "$(basename "$file")" != "index.html" ] && [ "$(basename "$file")" != "video1.mp4" ] && [ "$(basename "$file")" != "video2.mp4" ] && [ "$(basename "$file")" != "video3.mp4" ]; then
            sudo cp "$file" /var/www/html/
            log "Copied $(basename "$file")"
        fi
    done
    
    # Set permissions
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    log "Set permissions"
    
else
    log "ERROR: Repository directory not found at $REPO_DIR" >> $LOG_FILE
fi

# 4. Test and restart NGINX
log "Testing NGINX configuration..."
if sudo nginx -t >> $LOG_FILE 2>&1; then
    log "Configuration test passed, restarting NGINX..."
    sudo systemctl restart nginx
    
    # Verify it's running
    if systemctl is-active --quiet nginx; then
        log "✅ NGINX is running successfully"
        
        # Display server info
        IP=$(hostname -I | awk '{print $1}')
        log "Server IP: $IP"
        log "Access at: http://$IP/"
        
        # Create a quick info file
        echo "NGINX Server Information" > /home/pi/server-info.txt
        echo "IP Address: $IP" >> /home/pi/server-info.txt
        echo "Startup Time: $(date)" >> /home/pi/server-info.txt
        echo "Status: Running" >> /home/pi/server-info.txt
        echo "Files deployed:" >> /home/pi/server-info.txt
        ls -la /var/www/html/ >> /home/pi/server-info.txt
        
    else
        log "❌ NGINX failed to start"
    fi
else
    log "❌ NGINX configuration test failed"
fi

echo "=== Deployment complete ===" >> $LOG_FILE