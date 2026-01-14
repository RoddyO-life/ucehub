#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "UCEHub Backend Deployment v3.0"
echo "=========================================="

# Install Docker
yum update -y
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Get instance IP
INSTANCE_IP=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)
echo "Instance IP: $INSTANCE_IP"

# Create backend directory
mkdir -p /home/ec2-user/backend
cd /home/ec2-user/backend

# Download server.js and package.json from S3
aws s3 cp s3://ucehub-frontend-5095/backend/server.js ./server.js
aws s3 cp s3://ucehub-frontend-5095/backend/package.json ./package.json

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
CMD ["node", "server.js"]
EOF

# Build and run Docker container
docker build -t ucehub-backend:latest .
docker rm -f ucehub-backend-container || true
docker run -d \
  --name ucehub-backend-container \
  --restart unless-stopped \
  -p 3001:3001 \
  -e AWS_REGION="${region}" \
  -e CAFETERIA_TABLE="ucehub-cafeteria-orders-qa" \
  -e SUPPORT_TICKETS_TABLE="ucehub-support-tickets-qa" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="ucehub-absence-justifications-qa" \
  -e DOCUMENTS_BUCKET="ucehub-documents-qa-015109422820" \
  -e TEAMS_WEBHOOK_URL="${teams_webhook_url}" \
  -e PORT=3001 \
  ucehub-backend:latest

# Download and configure frontend
mkdir -p /usr/share/nginx/html
cd /usr/share/nginx/html
aws s3 sync s3://ucehub-frontend-5095/ . --exclude "backend/*"

# Configure nginx as reverse proxy
yum install -y nginx
cat > /etc/nginx/nginx.conf << 'NGINXEOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
        index        index.html;

        # Frontend - serve static files
        location / {
            try_files $uri $uri/ /index.html;
        }

        # API endpoints - proxy to backend
        location /api/ {
            proxy_pass http://localhost:3001;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /health {
            proxy_pass http://localhost:3001/health;
            proxy_http_version 1.1;
        }
    }
}
NGINXEOF

systemctl start nginx
systemctl enable nginx

echo "=========================================="
echo "Deployment Complete"
echo "Instance IP: $INSTANCE_IP"
echo "=========================================="
