# ========================================
# VPC
# ========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-${var.environment}"
    }
  )
}

# ========================================
# Internet Gateway
# ========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw-${var.environment}"
    }
  )
}

# ========================================
# Subnets Públicas
# ========================================

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-${var.availability_zones[count.index]}-${var.environment}"
      Tier = "Public"
    }
  )
}

# ========================================
# Subnets Privadas - App Tier
# ========================================

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-app-${var.availability_zones[count.index]}-${var.environment}"
      Tier = "Private-App"
    }
  )
}

# ========================================
# Subnets Privadas - Data Tier
# ========================================

resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-data-${var.availability_zones[count.index]}-${var.environment}"
      Tier = "Private-Data"
    }
  )
}

# ========================================
# Elastic IP para NAT
# ========================================

resource "aws_eip" "nat" {
  count  = var.enable_nat_instance ? 1 : (var.enable_nat_gateway ? 1 : 0)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-eip-${var.environment}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ========================================
# NAT Instance (Económico - $3.50/mes)
# ========================================

# Security Group para NAT Instance
resource "aws_security_group" "nat_instance" {
  count       = var.enable_nat_instance ? 1 : 0
  name        = "${var.project_name}-nat-sg-${var.environment}"
  description = "Security group for NAT Instance"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico desde VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all TCP from VPC"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all UDP from VPC"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow ICMP from VPC"
  }

  # Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-sg-${var.environment}"
    }
  )
}

# Buscar AMI de Amazon Linux 2023 (usaremos esta para NAT)
data "aws_ami" "nat_instance" {
  count       = var.enable_nat_instance ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# NAT Instance
resource "aws_instance" "nat" {
  count                  = var.enable_nat_instance ? 1 : 0
  ami                    = data.aws_ami.nat_instance[0].id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]
  source_dest_check      = false  # CRÍTICO para NAT

  # User data para configurar NAT
  user_data = <<-EOF
              #!/bin/bash
              # Habilitar IP forwarding
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p
              
              # Configurar iptables para NAT
              /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              /sbin/iptables -F FORWARD
              
              # Guardar reglas
              mkdir -p /etc/sysconfig
              /sbin/iptables-save > /etc/sysconfig/iptables
              
              # Hacer persistente en reinicio
              echo "iptables-restore < /etc/sysconfig/iptables" >> /etc/rc.local
              chmod +x /etc/rc.local
              EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-instance-${var.environment}"
    }
  )
}

# Asociar Elastic IP a NAT Instance
resource "aws_eip_association" "nat" {
  count         = var.enable_nat_instance ? 1 : 0
  instance_id   = aws_instance.nat[0].id
  allocation_id = aws_eip.nat[0].id
}

# ========================================
# NAT Gateway (Caro - $32/mes)
# ========================================

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-gw-${var.environment}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ========================================
# Route Tables
# ========================================

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt-${var.environment}"
    }
  )
}

# Asociaciones Route Table Pública
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Privada - App Tier
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-app-rt-${var.environment}"
    }
  )
}

# Ruta a NAT (Instance o Gateway)
resource "aws_route" "private_app_nat" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  
  # Si usa NAT Instance
  network_interface_id = var.enable_nat_instance ? aws_instance.nat[0].primary_network_interface_id : null
  
  # Si usa NAT Gateway
  nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

# Asociaciones Route Table Privada App
resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_subnets_cidr)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# Route Table Privada - Data Tier (sin acceso a internet)
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-data-rt-${var.environment}"
    }
  )
}

# Asociaciones Route Table Privada Data
resource "aws_route_table_association" "private_data" {
  count          = length(var.private_data_subnets_cidr)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data.id
}
