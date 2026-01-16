# Gold-pickleberry
Building a system vulnerable to basic DOS, demonstrating web server DoS vulnerabilities and defenses

LEGAL & ETHICAL DISCLAIMER
This lab is STRICTLY FOR EDUCATIONAL PURPOSES ONLY. All testing must be conducted in an isolated, controlled environment on equipment you own. Unauthorized testing on systems you do not own is illegal and unethical. By using this lab, you agree to use it responsibly and only for learning.

# Description
This project is a self-contained educational lab that demonstrates fundamental Denial-of-Service (DoS) vulnerabilities in an NGINX web server running on a Raspberry Pi. The system is intentionally configured with weaknesses to help understanding. The lab includes a multi-video streaming server as the target application. The following vulnerabilities are possible.


- Connection Pool Exhaustion
- Memory Resource Exhaustion
- Slowloris Vulnerability
- Lack of Rate Limiting






Technical Stack
Web Server: NGINX 1.14+ (intentionally misconfigured)

Hardware: Raspberry Pi 3/4 (ARM architecture)

Application: HTML5 video streaming server

Monitoring: htop, netstat, NGINX logs

Attack Tools: Python scripts, browser-based testing

🎯 Vulnerabilities Demonstrated
1. Connection Pool Exhaustion (Primary)
Vulnerable Config: worker_connections: 5

Attack Method: Connection Flood / Slowloris

Impact: Server stops accepting new connections after 5 concurrent

Time to Failure: Seconds

2. Memory Resource Exhaustion
Vulnerable Config: mp4_buffer_size: 500M, mp4_max_buffer_size: 1G

Attack Method: Multiple video stream requests

Impact: Raspberry Pi RAM exhaustion, OOM killer activation

Time to Failure: Minutes

3. Slowloris (Slow Request) Vulnerability
Vulnerable Config: client_header_timeout: 3600s, client_body_timeout: 3600s

Attack Method: Partial HTTP requests sent very slowly

Impact: Connections held open indefinitely, filling connection pool

Time to Failure: 1-2 minutes

4. Lack of Rate Limiting
Vulnerable Config: No limit_conn or limit_req directives

Attack Method: HTTP request flood

Impact: Unlimited requests from single IP, worker saturation

Time to Failure: Seconds to minutes

🚀 Setup & Installation
Prerequisites
Raspberry Pi 3/4 with Raspberry Pi OS (32/64-bit)

8GB+ SD card, stable power supply

Network connectivity (WiFi or Ethernet)

Basic Linux command line knowledge

Step 1: Initial Raspberry Pi Setup
bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install NGINX
sudo apt install nginx -y

# Install monitoring tools
sudo apt install htop net-tools dstat -y

# Install Python for attack scripts
sudo apt install python3 python3-pip -y
Step 2: Deploy Lab Files
bash
# Clone or copy lab files to Pi
cd /home/pi
git clone <repository-url> dos-lab
cd dos-lab

# Set up web content
sudo cp -r web-content/* /var/www/video_player/
sudo chown -R www-data:www-data /var/www/video_player

# Deploy vulnerable configuration
sudo cp nginx/nginx-vulnerable.conf /etc/nginx/nginx.conf
sudo cp nginx/sites-available/video-server-vulnerable /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/video-server-vulnerable /etc/nginx/sites-enabled/

# Test and restart NGINX
sudo nginx -t
sudo systemctl restart nginx
Step 3: Verify Installation
bash
# Check NGINX status
sudo systemctl status nginx

# Check listening ports
sudo netstat -tulpn | grep :80

# Test web server
curl http://localhost/
