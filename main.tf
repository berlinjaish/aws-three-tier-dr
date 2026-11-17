
resource "aws_vpc" "primary" {
  provider = aws.primary

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name   = "${local.project_prefix}-primary-vpc"
    Region = var.primary_region
  })
}
resource "aws_subnet" "public_1" {
  provider = aws.primary

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-public-subnet-1"
  })
}

resource "aws_subnet" "public_2" {
  provider = aws.primary

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-public-subnet-2"
  })
}

resource "aws_internet_gateway" "primary" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-primary-igw"
  })
}


resource "aws_route_table" "public" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-public-rt"
  })
}


resource "aws_route_table_association" "public_1" {
  provider = aws.primary

  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  provider = aws.primary

  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_subnet" "private_app_1" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-app-subnet-1"
    Tier = "Application"
  })
}

resource "aws_subnet" "private_app_2" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-app-subnet-2"
    Tier = "Application"
  })
}


resource "aws_subnet" "private_db_1" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-south-1a"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-db-subnet-1"
    Tier = "Database"
  })
}

resource "aws_subnet" "private_db_2" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-south-1b"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-db-subnet-2"
    Tier = "Database"
  })
}


resource "aws_route_table" "private_app" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-app-rt"
  })
}

resource "aws_route_table_association" "private_app_1" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_app_2" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_app.id
}



resource "aws_subnet" "private_web_1" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "ap-south-1a"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-web-subnet-1"
    Tier = "Web"
  })
}

resource "aws_subnet" "private_web_2" {
  provider = aws.primary

  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = "ap-south-1b"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-web-subnet-2"
    Tier = "Web"
  })
}


resource "aws_route_table" "private_web" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-web-rt"
  })
}

resource "aws_route_table_association" "private_web_1" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_web_1.id
  route_table_id = aws_route_table.private_web.id
}

resource "aws_route_table_association" "private_web_2" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_web_2.id
  route_table_id = aws_route_table.private_web.id
}

resource "aws_route_table" "private_db" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db_1" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_db_1.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_2" {
  provider = aws.primary

  subnet_id      = aws_subnet.private_db_2.id
  route_table_id = aws_route_table.private_db.id
}






# 1. Public ALB Security Group
resource "aws_security_group" "public_alb" {
  provider = aws.primary

  name        = "${local.project_prefix}-public-alb-sg"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = aws_vpc.primary.id

  # Inbound: Allow HTTP from the internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow HTTP to Web EC2 instances

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-public-alb-sg"
  })
}



# 2. Web EC2 Security Group
resource "aws_security_group" "web" {
  provider = aws.primary

  name        = "${local.project_prefix}-web-sg"
  description = "Allow HTTP only from Public ALB"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "HTTP from Public ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-web-sg"
  })
}


# Allow Public ALB to send HTTP traffic to Web EC2 instances
resource "aws_vpc_security_group_egress_rule" "public_alb_to_web" {
  provider = aws.primary

  security_group_id            = aws_security_group.public_alb.id
  referenced_security_group_id = aws_security_group.web.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "HTTP to Web EC2 instances"
}


# 3. Internal ALB Security Group
resource "aws_security_group" "internal_alb" {
  provider = aws.primary

  name        = "${local.project_prefix}-internal-alb-sg"
  description = "Allow application traffic from Web tier"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "Application traffic from Web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-internal-alb-sg"
  })
}

# 4. App EC2 Security Group
resource "aws_security_group" "app" {
  provider = aws.primary

  name        = "${local.project_prefix}-app-sg"
  description = "Allow application traffic only from Internal ALB"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "Application traffic from Internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-app-sg"
  })
}

# 5. RDS Security Group
resource "aws_security_group" "database" {
  provider = aws.primary

  name        = "${local.project_prefix}-database-sg"
  description = "Allow MySQL only from App tier"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "MySQL from App tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-database-sg"
  })
}




# Web Target Group
resource "aws_lb_target_group" "web" {
  provider = aws.primary

  name        = "${local.project_prefix}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

# App Target Group
resource "aws_lb_target_group" "app" {
  provider = aws.primary

  name        = "${local.project_prefix}-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}




# Public Application Load Balancer
resource "aws_lb" "public" {
  provider = aws.primary

  name               = "${local.project_prefix}-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb.id]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-public-alb"
  })
}

# Public ALB Listener
resource "aws_lb_listener" "public_http" {
  provider = aws.primary

  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}



# Internal Application Load Balancer
resource "aws_lb" "internal" {
  provider = aws.primary

  name               = "three-tier-dev-int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]

  subnets = [
    aws_subnet.private_app_1.id,
    aws_subnet.private_app_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "three-tier-dev-int-alb"
  })
}

# Internal ALB Listener
resource "aws_lb_listener" "internal_http" {
  provider = aws.primary

  load_balancer_arn = aws_lb.internal.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}




# Get the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023" {
  provider = aws.primary

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Web Server Launch Template
resource "aws_launch_template" "web" {
  provider = aws.primary

  name_prefix   = "${local.project_prefix}-web-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euo pipefail

# Install Apache
dnf install -y httpd

# Configure Apache reverse proxy
cat > /etc/httpd/conf.d/three-tier-proxy.conf <<'APACHE'
ProxyRequests Off
ProxyPreserveHost On

# Forward application requests
ProxyPass /app/ http://${aws_lb.internal.dns_name}:8080/ connectiontimeout=5 timeout=30
ProxyPassReverse /app/ http://${aws_lb.internal.dns_name}:8080/

# Forward database test requests
ProxyPass /db http://${aws_lb.internal.dns_name}:8080/db connectiontimeout=5 timeout=30
ProxyPassReverse /db http://${aws_lb.internal.dns_name}:8080/db
APACHE

# Create Web Tier homepage
cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>AWS Three Tier Architecture</title>
</head>
<body>
    <h1>Web Tier - AWS Three Tier Architecture</h1>
    <h2>Application Tier</h2>
    <a href="/app/">Open Application Tier</a>
    <h2>Database Tier</h2>
    <a href="/db">Test Database Connection</a>
</body>
</html>
HTML

# Validate Apache configuration
httpd -t

# Start Apache
systemctl enable --now httpd
EOF
  )



  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.project_prefix}-web-server"
    })
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }
}



# Web Tier Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  provider = aws.primary

  name = "${local.project_prefix}-web-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 2

  vpc_zone_identifier = [
    aws_subnet.private_web_1.id,
    aws_subnet.private_web_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${local.project_prefix}-web-server"
    propagate_at_launch = true
  }
}



# IAM role for Web EC2 instances
resource "aws_iam_role" "web_ssm" {
  name = "${local.project_prefix}-web-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# Allow EC2 to communicate with Systems Manager
resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile used by EC2 Launch Template
resource "aws_iam_instance_profile" "web" {
  name = "${local.project_prefix}-web-instance-profile"
  role = aws_iam_role.web_ssm.name
}




# IAM role for App EC2 instances
resource "aws_iam_role" "app_ssm" {
  name = "${local.project_prefix}-app-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# Allow App EC2 instances to communicate with Systems Manager
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for App EC2 Launch Template
resource "aws_iam_instance_profile" "app" {
  name = "${local.project_prefix}-app-instance-profile"
  role = aws_iam_role.app_ssm.name
}

# App Server Launch Template
resource "aws_launch_template" "app" {
  provider = aws.primary

  name_prefix   = "${local.project_prefix}-app-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  user_data = base64encode(<<-EOF_USER
#!/bin/bash
set -e

# Install required packages
dnf install -y python3 awscli-2 mariadb105

# Retrieve encrypted RDS password from SSM Parameter Store
aws ssm get-parameter \
  --name "/three-tier-dr/dev/db/password" \
  --with-decryption \
  --region ap-south-1 \
  --output json > /etc/three-tier-app-secret.json

chmod 600 /etc/three-tier-app-secret.json

# Application server
cat > /opt/app.py <<'PYTHON'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import subprocess
import os

with open("/etc/three-tier-app-secret.json") as f:
    secret = json.load(f)["Parameter"]["Value"]

DB_HOST = "${aws_db_instance.primary.address}"
DB_USER = "${var.db_username}"
DB_NAME = "appdb"

class AppHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        if self.path == "/db":
            try:
                result = subprocess.run(
                    [
                        "mysql",
                        "--connect-timeout=5",
                        "-h", DB_HOST,
                        "-u", DB_USER,
                        DB_NAME,
                        "-Nse", "SELECT 1"
                    ],
                    env={**os.environ, "MYSQL_PWD": secret},
                    capture_output=True,
                    text=True,
                    timeout=8
                )

                if result.returncode == 0 and result.stdout.strip() == "1":
                    self.send_response(200)
                    message = "Database connection successful"
                else:
                    self.send_response(503)
                    message = "Database connection failed"

            except Exception:
                self.send_response(503)
                message = "Database connection failed"

        else:
            self.send_response(200)
            message = "Application Tier - AWS Three Tier Architecture"

        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(message.encode())

HTTPServer(("0.0.0.0", 8080), AppHandler).serve_forever()
PYTHON

# Systemd service
cat > /etc/systemd/system/three-tier-app.service <<'SERVICE'
[Unit]
Description=Three Tier Application
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now three-tier-app
EOF_USER
  )


  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.project_prefix}-app-server"
    })
  }
}

# Application Tier Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  provider = aws.primary

  name = "${local.project_prefix}-app-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 2

  vpc_zone_identifier = [
    aws_subnet.private_app_1.id,
    aws_subnet.private_app_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${local.project_prefix}-app-server"
    propagate_at_launch = true
  }
}

# Allow Internal ALB to send traffic to App EC2 instances
resource "aws_vpc_security_group_egress_rule" "internal_alb_to_app" {
  provider = aws.primary

  security_group_id            = aws_security_group.internal_alb.id
  referenced_security_group_id = aws_security_group.app.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "HTTP traffic to App EC2 instances"
}

# Allow App EC2 instances to access HTTPS services through NAT
resource "aws_vpc_security_group_egress_rule" "app_https" {
  provider = aws.primary

  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS outbound for SSM and package installation"
}

# Allow Web EC2 instances to communicate with Internal ALB
resource "aws_vpc_security_group_egress_rule" "web_to_internal_alb" {
  provider = aws.primary

  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.internal_alb.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "Application traffic to Internal ALB"
}

# 6. RDS DB Subnet Group
resource "aws_db_subnet_group" "primary" {
  provider = aws.primary

  name        = "${local.project_prefix}-db-subnet-group"
  description = "Private DB subnets for MySQL"

  subnet_ids = [
    aws_subnet.private_db_1.id,
    aws_subnet.private_db_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-db-subnet-group"
  })
}

# 7. RDS MySQL Database
resource "aws_db_instance" "primary" {
  provider = aws.primary

  identifier        = "${local.project_prefix}-mysql-db"
  engine            = "mysql"
  engine_version    = "8.4.13"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  deletion_protection = false
  skip_final_snapshot = true

  copy_tags_to_snapshot = true

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-mysql-db"
  })
}

# Allow App EC2 instances to connect to private RDS MySQL
resource "aws_vpc_security_group_egress_rule" "app_to_database" {
  provider = aws.primary

  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.database.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "MySQL access from App tier to RDS"
}

# 8. NAT Gateway Elastic IP
resource "aws_eip" "nat" {
  provider = aws.primary

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-nat-eip"
  })
}

# 9. NAT Gateway in Public Subnet 1
resource "aws_nat_gateway" "primary" {
  provider = aws.primary

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.primary]
}

# 10. Private App Route through NAT
resource "aws_route" "private_app_nat" {
  provider = aws.primary

  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.primary.id
}

# 11. Private Web Route through NAT
resource "aws_route" "private_web_nat" {
  provider = aws.primary

  route_table_id         = aws_route_table.private_web.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.primary.id
}




# Store the RDS password securely in Parameter Store
resource "aws_ssm_parameter" "db_password" {
  provider = aws.primary

  name        = "/three-tier-dr/dev/db/password"
  description = "RDS password for the Three Tier App"
  type        = "SecureString"
  value       = var.db_password
  key_id      = "alias/aws/ssm"

  tags = local.common_tags
}

# Allow App EC2 instances to retrieve and decrypt the RDS password
resource "aws_iam_role_policy" "app_read_db_password" {
  name = "${local.project_prefix}-app-read-db-password"
  role = aws_iam_role.app_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = aws_ssm_parameter.db_password.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.ap-south-1.amazonaws.com"
          }
        }
      }
    ]
  })
}
