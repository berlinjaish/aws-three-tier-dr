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

# 2. Private Database Subnet - AZ A
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

# 3. Private Database Subnet - AZ B
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

# 4. Private Database Route Table
resource "aws_route_table" "dr_db" {
  provider = aws.dr

  vpc_id = aws_vpc.dr.id

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-private-db-rt"
  })
}

# 5. Associate Database Subnet A
resource "aws_route_table_association" "dr_db_1" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_db_1.id
  route_table_id = aws_route_table.dr_db.id
}

# 6. Associate Database Subnet B
resource "aws_route_table_association" "dr_db_2" {
  provider = aws.dr

  subnet_id      = aws_subnet.dr_db_2.id
  route_table_id = aws_route_table.dr_db.id
}

# 7. DR Database Security Group
resource "aws_security_group" "dr_database" {
  provider = aws.dr

  name        = "${local.project_prefix}-dr-database-sg"
  description = "Private DR MySQL database security group"
  vpc_id      = aws_vpc.dr.id

  # No inbound access until the DR application tier is configured.

  tags = merge(local.common_tags, {
    Name = "${local.project_prefix}-dr-database-sg"
    Tier = "Database"
  })
}

# 8. DR RDS Subnet Group
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
# Restore from encrypted Mumbai snapshot
# ==========================================

resource "aws_db_instance" "dr" {
  provider = aws.dr

  identifier = "${local.project_prefix}-mysql-dr"

  # Restore from the encrypted snapshot copied to Hyderabad
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

# ==========================================
