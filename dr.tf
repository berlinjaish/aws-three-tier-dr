
# ==========================================
# HYDERABAD DISASTER RECOVERY NETWORK
# Region: ap-south-2
# Strategy: Backup and Restore
# ==========================================

# 1. DR VPC
resource "aws_vpc" "dr" {
  provider = aws.dr

  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-vpc"
    Tier = "Disaster-Recovery"
  })
}

# ==========================================
# DR PUBLIC NETWORK
# ==========================================

# 2. DR Internet Gateway
resource "aws_internet_gateway" "dr" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-igw"
    Tier = "Disaster-Recovery"
  })
}

# 3. DR Public Subnet - AZ A
resource "aws_subnet" "dr_public_1" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-public-1"
    Tier = "Public"
  })
}

# 4. DR Public Subnet - AZ B
resource "aws_subnet" "dr_public_2" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-public-2"
    Tier = "Public"
  })
}

# 5. DR Public Route Table
resource "aws_route_table" "dr_public" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-public-rt"
    Tier = "Public"
  })
}

# 6. DR Public Internet Route
resource "aws_route" "dr_public_internet" {
  provider = aws.dr

  route_table_id         = aws_route_table.dr_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dr.id
}

# 7. Associate Public Subnet A
resource "aws_route_table_association" "dr_public_1" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_public_1.id
  route_table_id = aws_route_table.dr_public.id
}

# 8. Associate Public Subnet B
resource "aws_route_table_association" "dr_public_2" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_public_2.id
  route_table_id = aws_route_table.dr_public.id
}

# ==========================================
# DR PRIVATE DATABASE NETWORK
# ==========================================

# 9. Private Database Subnet - AZ A
resource "aws_subnet" "dr_db_1" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.5.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-db-1"
    Tier = "Database"
  })
}

# 10. Private Database Subnet - AZ B
resource "aws_subnet" "dr_db_2" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.6.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-db-2"
    Tier = "Database"
  })
}

# 11. Private Database Route Table
resource "aws_route_table" "dr_db" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-db-rt"
    Tier = "Database"
  })
}

# 12. Associate Database Subnet A
resource "aws_route_table_association" "dr_db_1" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_db_1.id
  route_table_id = aws_route_table.dr_db.id
}

# 13. Associate Database Subnet B
resource "aws_route_table_association" "dr_db_2" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_db_2.id
  route_table_id = aws_route_table.dr_db.id
}

# ==========================================
# DR DATABASE SECURITY
# ==========================================

# 14. DR Database Security Group
resource "aws_security_group" "dr_database" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-database-sg"
  description = "Private DR MySQL database security group"
  vpc_id      = aws_vpc.dr.id

  # Inbound access configured separately.

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-database-sg"
    Tier = "Database"
  })
}

# 15. DR RDS Subnet Group
resource "aws_db_subnet_group" "dr" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-db-subnet-group"
  description = "Private Hyderabad DR database subnets"

  subnet_ids = [
    aws_subnet.dr_db_1.id,
    aws_subnet.dr_db_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-db-subnet-group"
  })
}

# ==========================================
# HYDERABAD DISASTER RECOVERY RDS
# ==========================================

resource "aws_db_instance" "dr" {
  provider = aws.dr

  identifier = "${local.project_prefix}-mysql-dr"

  # Preserve existing restored snapshot.
  snapshot_identifier = "aws-three-tier-dr-dev-mysql-dr-copy-20261117"

  instance_class    = "db.t3.micro"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.dr.name
  vpc_security_group_ids = [aws_security_group.dr_database.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  deletion_protection   = false
  skip_final_snapshot   = true
  copy_tags_to_snapshot = true

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-mysql-dr"
    Tier = "Database"
    Role = "Disaster-Recovery"
  })
}

# Recovered Hyderabad DR database
data "aws_db_instance" "dr_recovered" {
  provider = aws.dr

  db_instance_identifier = "aws-three-tier-dr-dev-mysql-dr-recovered"
}


# ==========================================
# HYDERABAD DR PRIVATE WEB SUBNETS
# ==========================================

# 16. DR Private Web Subnet - AZ A
resource "aws_subnet" "dr_web_1" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.3.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-web-1"
    Tier = "Web"
  })
}

# 17. DR Private Web Subnet - AZ B
resource "aws_subnet" "dr_web_2" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.4.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-web-2"
    Tier = "Web"
  })
}

# DR Web Route Table
resource "aws_route_table" "dr_web" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-web-rt"
    Tier = "Web"
  })
}

resource "aws_route_table_association" "dr_web_1" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_web_1.id
  route_table_id = aws_route_table.dr_web.id
}

resource "aws_route_table_association" "dr_web_2" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_web_2.id
  route_table_id = aws_route_table.dr_web.id
}

# ==========================================
# HYDERABAD DR PRIVATE APPLICATION SUBNETS
# ==========================================

resource "aws_subnet" "dr_app_1" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.7.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-app-1"
    Tier = "Application"
  })
}

resource "aws_subnet" "dr_app_2" {
  provider = aws.dr

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.8.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-app-2"
    Tier = "Application"
  })
}

# DR Application Route Table
resource "aws_route_table" "dr_app" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-app-rt"
    Tier = "Application"
  })
}

resource "aws_route_table_association" "dr_app_1" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_app_1.id
  route_table_id = aws_route_table.dr_app.id
}

resource "aws_route_table_association" "dr_app_2" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_app_2.id
  route_table_id = aws_route_table.dr_app.id
}

# ==========================================
# DR SECURITY GROUPS
# ==========================================

resource "aws_security_group" "dr_public_alb" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-public-alb-sg"
  description = "Allow public HTTP traffic to DR web load balancer"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-public-alb-sg"
    Tier = "Public-ALB"
  })
}

resource "aws_security_group" "dr_web" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-web-sg"
  description = "Allow HTTP only from the DR public ALB"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "HTTP from public ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_public_alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-web-sg"
    Tier = "Web"
  })
}

resource "aws_security_group" "dr_internal_alb" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-internal-alb-sg"
  description = "Allow application traffic from DR web tier"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "HTTP 8080 from DR web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_web.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-internal-alb-sg"
    Tier = "Internal-ALB"
  })
}

resource "aws_security_group" "dr_app" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-app-sg"
  description = "Allow application traffic only from DR internal ALB"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "Application traffic from DR internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_internal_alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-sg"
    Tier = "Application"
  })
}

# DR Application to DR Database
resource "aws_vpc_security_group_ingress_rule" "dr_app_to_database" {
  provider = aws.dr

  security_group_id            = aws_security_group.dr_database.id
  referenced_security_group_id = aws_security_group.dr_app.id

  description = "Allow MySQL from Hyderabad DR application servers"

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-to-database"
  })
}

# ==========================================
# HYDERABAD DR DATABASE PASSWORD
# ==========================================

resource "aws_ssm_parameter" "dr_db_password" {
  provider = aws.dr

  name        = "/three-tier-dr/dev/db/password"
  description = "Secure database password for Hyderabad DR application"
  type        = "SecureString"
  value       = var.db_password
  key_id      = "alias/aws/ssm"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-db-password"
    Tier = "Database"
  })
}

# ==========================================
# HYDERABAD DR APPLICATION IAM
# ==========================================

resource "aws_iam_role" "dr_app_ssm" {
  name = "${local.project_prefix}-dr-app-ssm-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-ssm-role"
    Tier = "Application"
  })
}

resource "aws_iam_role_policy_attachment" "dr_app_ssm" {
  role       = aws_iam_role.dr_app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# UPDATED: SSM and KMS permissions for SecureString retrieval
resource "aws_iam_role_policy" "dr_app_read_db_password" {
  name = "${local.project_prefix}-dr-app-read-db-password"
  role = aws_iam_role.dr_app_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:ap-south-2:357558450991:parameter/three-tier-dr/dev/db/password"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:ap-south-2:357558450991:key/ca01c016-9264-44c6-9d70-cb17fa4d9ea9"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.ap-south-2.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dr_app" {
  name = "${local.project_prefix}-dr-app-instance-profile"
  role = aws_iam_role.dr_app_ssm.name

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-instance-profile"
    Tier = "Application"
  })
}

# ==========================================
# HYDERABAD DR NAT GATEWAY
# ==========================================

resource "aws_eip" "dr_nat" {
  provider = aws.dr

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-nat-eip"
    Tier = "Networking"
  })
}

resource "aws_nat_gateway" "dr" {
  provider = aws.dr

  allocation_id = aws_eip.dr_nat.id
  subnet_id     = aws_subnet.dr_public_1.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-nat-gateway"
    Tier = "Networking"
  })

  depends_on = [aws_internet_gateway.dr]
}

resource "aws_route" "dr_web_nat" {
  provider = aws.dr

  route_table_id         = aws_route_table.dr_web.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dr.id
}

resource "aws_route" "dr_app_nat" {
  provider = aws.dr

  route_table_id         = aws_route_table.dr_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dr.id
}

# ==========================================
# DR AMAZON LINUX 2023 AMI
# ==========================================

data "aws_ssm_parameter" "dr_al2023" {
  provider = aws.dr

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ==========================================
# HYDERABAD DR APPLICATION LAUNCH TEMPLATE
# ==========================================

resource "aws_launch_template" "dr_app" {
  provider = aws.dr

  name_prefix   = "${local.project_prefix}-dr-app-"
  image_id      = data.aws_ssm_parameter.dr_al2023.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.dr_app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.dr_app.name
  }

  user_data = base64encode(<<-EOF_USER
#!/bin/bash
set -e

dnf install -y python3 awscli-2 mariadb105

aws ssm get-parameter \
  --name "/three-tier-dr/dev/db/password" \
  --with-decryption \
  --region ap-south-2 \
  --output json > /etc/three-tier-app-secret.json

chmod 600 /etc/three-tier-app-secret.json

cat > /opt/app.py <<'PYTHON'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import subprocess
import os

with open("/etc/three-tier-app-secret.json") as f:
    secret = json.load(f)["Parameter"]["Value"]

DB_HOST = "${data.aws_db_instance.dr_recovered.address}"
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
                    message = "DR Database connection successful"
                else:
                    self.send_response(503)
                    message = "DR Database connection failed"

            except Exception:
                self.send_response(503)
                message = "DR Database connection failed"
        else:
            self.send_response(200)
            message = "Hyderabad DR Application Tier"

        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(message.encode())

HTTPServer(("0.0.0.0", 8080), AppHandler).serve_forever()
PYTHON

cat > /etc/systemd/system/three-tier-app.service <<'SERVICE'
[Unit]
Description=Three Tier DR Application
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
      Name = "${local.project_prefix}-dr-app-server"
      Tier = "Application"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-launch-template"
    Tier = "Application"
  })
}

# ==========================================
# HYDERABAD DR APPLICATION AUTO SCALING
# ==========================================

resource "aws_autoscaling_group" "dr_app" {
  provider = aws.dr

  name = "${local.project_prefix}-dr-app-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 2

  vpc_zone_identifier = [
    aws_subnet.dr_app_1.id,
    aws_subnet.dr_app_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.dr_app.arn
  ]

  launch_template {
    id      = aws_launch_template.dr_app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${local.project_prefix}-dr-app-server"
    propagate_at_launch = true
  }
}

# ==========================================
# HYDERABAD DR APPLICATION TARGET GROUP
# ==========================================

resource "aws_lb_target_group" "dr_app" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
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

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-app-tg"
    Tier = "Application"
  })
}

# ==========================================
# HYDERABAD DR INTERNAL APPLICATION ALB
# ==========================================

resource "aws_lb" "dr_internal" {
  provider = aws.dr

  name               = "${local.project_prefix}-dr-int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dr_internal_alb.id]

  subnets = [
    aws_subnet.dr_app_1.id,
    aws_subnet.dr_app_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-int-alb"
    Tier = "Application"
  })
}

resource "aws_lb_listener" "dr_internal_http" {
  provider = aws.dr

  load_balancer_arn = aws_lb.dr_internal.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_app.arn
  }
}

# ==========================================
# HYDERABAD DR WEB TARGET GROUP
# ==========================================

resource "aws_lb_target_group" "dr_web" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
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

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-web-tg"
    Tier = "Web"
  })
}

# ==========================================
# HYDERABAD DR PUBLIC APPLICATION ALB
# ==========================================

resource "aws_lb" "dr_public" {
  provider = aws.dr

  name               = "three-tier-dr-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dr_public_alb.id]

  subnets = [
    aws_subnet.dr_public_1.id,
    aws_subnet.dr_public_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-public-alb"
    Tier = "Web"
  })
}

resource "aws_lb_listener" "dr_public_http" {
  provider = aws.dr

  load_balancer_arn = aws_lb.dr_public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_web.arn
  }
}

# ==========================================
# HYDERABAD DR WEB LAUNCH TEMPLATE
# ==========================================

resource "aws_launch_template" "dr_web" {
  provider = aws.dr

  name_prefix   = "${local.project_prefix}-dr-web-"
  image_id      = data.aws_ssm_parameter.dr_al2023.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.dr_web.id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euo pipefail

dnf install -y httpd

cat > /etc/httpd/conf.d/three-tier-proxy.conf <<'APACHE'
ProxyRequests Off
ProxyPreserveHost On

ProxyPass /app/ http://${aws_lb.dr_internal.dns_name}:8080/ connectiontimeout=5 timeout=30
ProxyPassReverse /app/ http://${aws_lb.dr_internal.dns_name}:8080/

ProxyPass /db http://${aws_lb.dr_internal.dns_name}:8080/db connectiontimeout=5 timeout=30
ProxyPassReverse /db http://${aws_lb.dr_internal.dns_name}:8080/db
APACHE

cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>AWS Three Tier DR Architecture</title>
</head>
<body>
    <h1>Hyderabad DR Web Tier</h1>
    <h2>Application Tier</h2>
    <a href="/app/">Open DR Application Tier</a>
    <h2>Database Tier</h2>
    <a href="/db">Test DR Database Connection</a>
</body>
</html>
HTML

httpd -t
systemctl enable --now httpd
EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.dr_web.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.project_prefix}-dr-web-server"
      Tier = "Web"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-web-launch-template"
    Tier = "Web"
  })
}

# ==========================================
# HYDERABAD DR WEB IAM ROLE
# ==========================================

resource "aws_iam_role" "dr_web_ssm" {
  provider = aws.dr

  name = "${local.project_prefix}-dr-web-ssm-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-web-ssm-role"
    Tier = "Web"
  })
}

resource "aws_iam_role_policy_attachment" "dr_web_ssm" {
  provider = aws.dr

  role       = aws_iam_role.dr_web_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "dr_web" {
  provider = aws.dr

  name = "${local.project_prefix}-dr-web-instance-profile"
  role = aws_iam_role.dr_web_ssm.name

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-web-instance-profile"
    Tier = "Web"
  })
}

# ==========================================
# HYDERABAD DR WEB AUTO SCALING GROUP
# ==========================================

resource "aws_autoscaling_group" "dr_web" {
  provider = aws.dr

  name = "${local.project_prefix}-dr-web-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 2

  vpc_zone_identifier = [
    aws_subnet.dr_web_1.id,
    aws_subnet.dr_web_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.dr_web.arn
  ]

  launch_template {
    id      = aws_launch_template.dr_web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${local.project_prefix}-dr-web-server"
    propagate_at_launch = true
  }
}
