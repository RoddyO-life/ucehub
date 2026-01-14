#!/bin/bash
# Minimal User Data Script - No external downloads required
# Works without internet connectivity

set -e
set -x

echo "===== Starting minimal instance configuration ====="
echo "Environment: ${environment}"
echo "Project: ${project_name}"

# Install Docker (Amazon Linux 2023 includes it in default repos)
yum install -y docker || dnf install -y docker

# Start Docker
systemctl start docker
systemctl enable docker

# Create nginx config for health check
mkdir -p /opt/nginx
cat > /opt/nginx/default.conf <<'EOF'
server {
    listen 80;
    location / {
        return 200 '<html><head><title>UCEHub - ${environment}</title></head><body><h1>UCEHub - ${environment} Environment</h1><p>Instance ready</p></body></html>';
        add_header Content-Type text/html;
    }
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Wait for Docker daemon
sleep 10

# Start nginx container with health endpoint
docker run -d \
    --name ucehub-app \
    --restart unless-stopped \
    -p 80:80 \
    -v /opt/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
    ${docker_image}

echo "===== Instance configuration completed ====="
exit 0
