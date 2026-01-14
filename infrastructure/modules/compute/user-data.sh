#!/bin/bash
# User Data Script for EC2 Instances
# Installs Docker, configures logging, and starts application containers

set -e  # Exit on error
set -x  # Print commands for debugging

# ============================================================================
# SYSTEM UPDATES AND BASIC TOOLS
# ============================================================================
echo "===== Starting instance configuration ====="
echo "Environment: ${environment}"
echo "Project: ${project_name}"

# Skip system update to speed up bootstrap (can be done later via cron)
# dnf update -y

# Install essential tools
dnf install -y \
    curl \
    wget \
    git \
    jq \
    htop \
    unzip \
    amazon-cloudwatch-agent

# ============================================================================
# DOCKER INSTALLATION
# ============================================================================
echo "===== Installing Docker ====="

# Install Docker
dnf install -y docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group (for non-root access)
usermod -aG docker ec2-user

# Install Docker Compose
DOCKER_COMPOSE_VERSION="2.24.0"
curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
docker --version
docker-compose --version

# ============================================================================
# CLOUDWATCH AGENT CONFIGURATION
# ============================================================================
echo "===== Configuring CloudWatch Agent ====="

cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/${project_name}/${environment}/system",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "/${project_name}/${environment}/docker",
            "log_stream_name": "{instance_id}/docker"
          },
          {
            "file_path": "/var/log/app/*.log",
            "log_group_name": "/${project_name}/${environment}/application",
            "log_stream_name": "{instance_id}/app"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# ============================================================================
# APPLICATION DIRECTORY SETUP
# ============================================================================
echo "===== Setting up application directory ====="

mkdir -p /opt/app
mkdir -p /var/log/app
chown -R ec2-user:ec2-user /opt/app
chown -R ec2-user:ec2-user /var/log/app

cd /opt/app

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
echo "===== Configuring environment variables ====="

# Parse JSON environment variables
echo '${app_environment}' > /opt/app/.env.json

# Create .env file for Docker
cat > /opt/app/.env <<'ENVEOF'
NODE_ENV=${environment}
PROJECT_NAME=${project_name}
CONTAINER_PORT=${container_port}
ENVEOF

# Add custom environment variables from JSON
jq -r 'to_entries | .[] | "\(.key)=\(.value)"' /opt/app/.env.json >> /opt/app/.env

# ============================================================================
# NGINX CONFIGURATION FOR HEALTH CHECK
# ============================================================================
echo "===== Creating nginx configuration ====="

mkdir -p /opt/app/nginx
cat > /opt/app/nginx/default.conf <<'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        return 200 '<html><head><title>UCEHub - QA</title></head><body><h1>UCEHub - QA Environment</h1><p>Instance ready. Application running.</p></body></html>';
        add_header Content-Type text/html;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINXEOF

chown -R ec2-user:ec2-user /opt/app/nginx

# ============================================================================
# DOCKER COMPOSE CONFIGURATION
# ============================================================================
echo "===== Creating Docker Compose configuration ====="

cat > /opt/app/docker-compose.yml <<'COMPOSEEOF'
version: '3.8'

services:
  app:
    image: ${docker_image}
    container_name: ucehub-app
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - NODE_ENV=${environment}
      - PROJECT_NAME=${project_name}
    env_file:
      - .env
    volumes:
      - /var/log/app:/app/logs
      - /opt/app/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
COMPOSEEOF

chown ec2-user:ec2-user /opt/app/docker-compose.yml

# ============================================================================
# SYSTEMD SERVICE FOR APPLICATION
# ============================================================================
echo "===== Creating systemd service ====="

cat > /etc/systemd/system/ucehub-app.service <<'SERVICEEOF'
[Unit]
Description=UCEHub Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/app
ExecStartPre=/usr/bin/docker-compose pull
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=300
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable ucehub-app.service

# ============================================================================
# START APPLICATION
# ============================================================================
echo "===== Starting application ====="

# For initial deployment, we might not have a Docker image yet
# So we'll create a simple health check endpoint using nginx
if [ "${docker_image}" = "nginx:alpine" ]; then
    echo "Using default nginx image for initial setup"
    
    # Start with docker-compose
    cd /opt/app
    sudo -u ec2-user docker-compose up -d
    
elif [ -n "${docker_image}" ]; then
    echo "Pulling and starting application: ${docker_image}"
    
    # Pull the image
    sudo -u ec2-user docker pull ${docker_image} || true
    
    # Start the application
    systemctl start ucehub-app.service
else
    echo "No Docker image specified, creating placeholder service"
    
    # Start a simple nginx container as placeholder
    docker run -d \
        --name ucehub-placeholder \
        --restart unless-stopped \
        -p 80:80 \
        -e ENVIRONMENT=${environment} \
        nginx:alpine
    
    # Create a custom index page
    docker exec ucehub-placeholder sh -c 'echo "<h1>UCEHub - ${environment}</h1><p>Instance is ready. Waiting for application deployment.</p>" > /usr/share/nginx/html/index.html'
fi

# ============================================================================
# HEALTH CHECK SCRIPT
# ============================================================================
echo "===== Creating health check script ====="

cat > /usr/local/bin/health-check.sh <<'HEALTHEOF'
#!/bin/bash
# Health check script for monitoring

CONTAINER_PORT=${container_port}

if curl -f -s http://localhost:$${CONTAINER_PORT}/health > /dev/null 2>&1; then
    echo "OK: Application is healthy"
    exit 0
else
    echo "ERROR: Application health check failed"
    exit 1
fi
HEALTHEOF

chmod +x /usr/local/bin/health-check.sh

# ========================================================================================================================
# AUTOMATIC SECURITY UPDATES (Disabled - can be enabled later after NAT is stable)
# ============================================================================
# echo "===== Configuring automatic security updates ====="
# dnf install -y dnf-automatic
# sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
# systemctl enable --now dnf-automatic.timer

# ============================================================================
# INSTANCE METADATA
# ============================================================================
echo "===== Retrieving instance metadata ====="

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
LOCAL_IPV4=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)

echo "Instance ID: $INSTANCE_ID"
echo "Availability Zone: $AVAILABILITY_ZONE"
echo "Local IPv4: $LOCAL_IPV4"

# Save metadata
cat > /opt/app/instance-metadata.json <<METAEOF
{
  "instance_id": "$INSTANCE_ID",
  "availability_zone": "$AVAILABILITY_ZONE",
  "local_ipv4": "$LOCAL_IPV4",
  "environment": "${environment}",
  "project": "${project_name}",
  "deployment_time": "$(date -Iseconds)"
}
METAEOF

# ============================================================================
# COMPLETION
# ============================================================================
echo "===== Instance configuration completed successfully ====="
echo "Instance is ready to serve traffic"

# Send completion signal to CloudWatch
aws cloudwatch put-metric-data \
    --namespace "${project_name}/${environment}" \
    --metric-name InstanceBootstrap \
    --value 1 \
    --dimensions Instance=$INSTANCE_ID \
    --region $(ec2-metadata --availability-zone | cut -d " " -f 2 | sed 's/.$//')

exit 0
