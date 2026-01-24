#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y \
  curl \
  wget \
  unzip \
  vim \
  net-tools \
  git

# ========================================
# Install Prometheus
# ========================================
echo "Installing Prometheus..."
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0.linux-amd64
cp prometheus promtool /usr/local/bin/
cp -r consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'apps'
    static_configs:
      - targets: ['${alb_dns}:80'] # Target ALB for health metrics or use EC2 discovery if configured
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create systemd service for Prometheus
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=http://${alb_dns}/prometheus/ \
  --web.route-prefix=/prometheus

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# ========================================
# Install Grafana
# ========================================
echo "Installing Grafana..."
# Add Grafana repository
cat > /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

yum install -y grafana

# Configure Grafana subpath and admin password
cat > /etc/grafana/grafana.ini <<EOF
[server]
protocol = http
http_port = 3000
domain = ${alb_dns}
root_url = %(protocol)s://%(domain)s/grafana/
serve_from_sub_path = true

[security]
admin_user = admin
admin_password = GrafanaAdmin@2024!

[auth.anonymous]
enabled = true
org_role = Viewer

[analytics]
enabled = false
EOF

# Provision Data Sources
mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/datasources.yaml <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090/prometheus
    isDefault: true
    editable: false
  
  - name: CloudWatch
    type: cloudwatch
    jsonData:
      authType: default
      defaultRegion: us-east-1
    editable: false
EOF

# ========================================
# Start Services
# ========================================
systemctl daemon-reload
systemctl enable prometheus grafana-server
systemctl start prometheus grafana-server

echo "Monitoring stack installation complete!"
