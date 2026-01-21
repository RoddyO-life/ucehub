#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
  curl \
  wget \
  unzip \
  vim \
  net-tools \
  supervisor

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus || true

# Download and install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-2.40.0.linux-amd64.tar.gz
cd prometheus-2.40.0.linux-amd64

# Copy Prometheus binaries
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

# Create Prometheus directory structure
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ec2'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create systemd service file
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
  --web.listen-address=0.0.0.0:9090

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Prometheus
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Verify Prometheus is running
sleep 5
curl -f http://localhost:9090/-/healthy || exit 1

echo "Prometheus installed and running on port 9090"
