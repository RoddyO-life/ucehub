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
  software-properties-common

# Add Grafana repository
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

# Install Grafana
apt-get update
apt-get install -y grafana-server

# Create Grafana datasources directory
mkdir -p /etc/grafana/provisioning/datasources

# Configure Prometheus data source
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF

# Update Grafana configuration for production
cat >> /etc/grafana/grafana.ini <<EOF

[security]
admin_password = GrafanaAdmin@2024!

[auth]
disable_login_form = false

[auth.anonymous]
enabled = true
org_role = Viewer

[users]
allow_sign_up = false

[smtp]
enabled = false
EOF

# Enable and start Grafana
systemctl enable grafana-server
systemctl start grafana-server

# Verify Grafana is running
sleep 5
curl -f http://localhost:3000/api/health || exit 1

echo "Grafana installed and running on port 3000"
echo "Default credentials: admin / GrafanaAdmin@2024!"
