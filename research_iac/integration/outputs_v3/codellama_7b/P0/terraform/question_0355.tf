provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  vpc_id            = aws_vpc.example.id
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_iam_role" "rds_proxy_role" {
  name               = "rds-proxy-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name   = "rds-proxy-policy"
  role   = aws_iam_role.rds_proxy_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "${aws_secretsmanager_secret.rds_proxy_credentials.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_secretsmanager_secret" "rds_proxy_credentials" {
  name = "rds-proxy-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_proxy_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_proxy_credentials.id
  secret_string = jsonencode({ username = "myuser", password = "mypass" })
}

resource "aws_db_instance" "example" {
  identifier             = "example-aurora-mysql"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.03.1"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_encrypted      = true
  apply_immediately      = true
  copy_tags_to_snapshot  = true
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_proxy_role.arn
  performance_insights_enabled = true
  performance_insights_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/my-key"
  preferred_backup_window = "07:00-09:00"
  backup_retention_period = 5
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.example.name
  multi_az               = true
  publicly_accessible     = false
  storage_type           = "gp2"
}

resource "aws_db_subnet_group" "example" {
  name       = "example-aurora-mysql"
  subnet_ids = aws_subnet.example[*].id
}