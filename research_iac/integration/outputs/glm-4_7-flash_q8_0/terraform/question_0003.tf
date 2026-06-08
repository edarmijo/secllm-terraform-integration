# Provider Configuration
provider "aws" {
  alias  = "main"
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-central"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "ap-southeast"
  region = "ap-southeast-1"
}

# Variables for Database Credentials
variable "db_username" {
  type        = string
  default     = "admin"
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  default     = "password123"
  description = "Database password"
}

# IAM Role for RDS (Optional but recommended for best practices)
resource "aws_iam_role" "rds_role" {
  name = "rds_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_attach" {
  role       = aws_iam_role.rds_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSServiceRoleForRDS"
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "main."
}

# Primary DB Instance
resource "aws_db_instance" "primary" {
  provider            = aws.main
  identifier          = "primary"
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "maindb"
  username            = var.db_username
  password            = var.db_password
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_role_arn        = aws_iam_role.rds_role.arn
}

# Replica 1: us-east-1
resource "aws_db_instance" "replica_us_east" {
  provider            = aws.us-east
  identifier          = "replica_us_east"
  source_db_instance_identifier = aws_db_instance.primary.identifier
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "maindb"
  username            = var.db_username
  password            = var.db_password
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_role_arn        = aws_iam_role.rds_role.arn
}

# Replica 2: eu-central-1
resource "aws_db_instance" "replica_eu_central" {
  provider            = aws.eu-central
  identifier          = "replica_eu_central"
  source_db_instance_identifier = aws_db_instance.primary.identifier
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "maindb"
  username            = var.db_username
  password            = var.db_password
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_role_arn        = aws_iam_role.rds_role.arn
}

# Replica 3: ap-southeast-1
resource "aws_db_instance" "replica_ap_southeast" {
  provider            = aws.ap-southeast
  identifier          = "replica_ap_southeast"
  source_db_instance_identifier = aws_db_instance.primary.identifier
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "maindb"
  username            = var.db_username
  password            = var.db_password
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_role_arn        = aws_iam_role.rds_role.arn
}

# Security Group (Required for RDS)
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for DB instances"

  tags = {
    Name = "db_sg"
  }
}

# Route 53 Weighted Record - Primary
resource "aws_route53_record" "weighted_primary" {
  name    = "db.main"
  type    = "A"
  zone_id = aws_route53_zone.main.id

  set_identifier = "primary"
  weight         = 100
  provider       = aws.main
  alias {
    name                   = aws_db_instance.primary.endpoint
    zone_id                 = aws_db_instance.primary.endpoint
    evaluate_target_health = true
  }
}

# Route 53 Weighted Record - Replica US East
resource "aws_route53_record" "weighted_replica_us_east" {
  name    = "db.main"
  type    = "A"
  zone_id = aws_route53_zone.main.id

  set_identifier = "replica_us_east"
  weight         = 50
  provider       = aws.us-east
  alias {
    name                   = aws_db_instance.replica_us_east.endpoint
    zone_id                 = aws_db_instance.replica_us_east.endpoint
    evaluate_target_health = true
  }
}

# Route 53 Weighted Record - Replica EU Central
resource "aws_route53_record" "weighted_replica_eu_central" {
  name    = "db.main"
  type    = "A"
  zone_id = aws_route53_zone.main.id

  set_identifier = "replica_eu_central"
  weight         = 50
  provider       = aws.eu-central
  alias {
    name                   = aws_db_instance.replica_eu_central.endpoint
    zone_id                 = aws_db_instance.replica_eu_central.endpoint
    evaluate_target_health = true
  }
}

# Route 53 Weighted Record - Replica AP Southeast
resource "aws_route53_record" "weighted_replica_ap_southeast" {
  name    = "db.main"
  type    = "A"
  zone_id = aws_route53_zone.main.id

  set_identifier = "replica_ap_southeast"
  weight         = 50
  provider       = aws.ap-southeast
  alias {
    name                   = aws_db_instance.replica_ap_southeast.endpoint
    zone_id                 = aws_db_instance.replica_ap_southeast.endpoint
    evaluate_target_health = true
  }
}