provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "database_credentials" {
  name = "database-credentials"
}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = data.aws_secretsmanager_secret.database_credentials.id
}

resource "aws_iam_role" "database_restore_role" {
  name        = "database-restore-role"
  description = "Role for restoring database from S3"

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

resource "aws_iam_role_policy" "database_restore_policy" {
  name   = "database-restore-policy"
  role   = aws_iam_role.database_restore_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "rds:RestoreDBInstanceFromS3"
        ]
        Effect = "Allow"
        Resource = [
          data.aws_s3_bucket.database_backup.arn,
          "${aws_caller_identity.current_arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "database_restore_profile" {
  name = "database-restore-profile"
  role = aws_iam_role.database_restore_role.name
}

data "aws_s3_bucket" "database_backup" {
  bucket = var.database_backup_bucket_name
}

resource "aws_rds_cluster" "database_cluster" {
  cluster_identifier      = "database-cluster"
  engine                 = "aurora-postgresql"
  instance_class         = "db.r5.large"
  database_name          = "mydatabase"
  master_username        = data.aws_secretsmanager_secret_version.database_credentials.secret_string["username"]
  master_user_password   = data.aws_secretsmanager_secret_version.database_credentials.secret_string["password"]
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  iam_database_authentication_enabled = true
}

resource "aws_rds_cluster_instance" "database_instance" {
  cluster_identifier      = aws_rds_cluster.database_cluster.cluster_identifier
  instance_class         = "db.r5.large"
  engine                 = aws_rds_cluster.database_cluster.engine
  identifier             = "database-instance"
  database_name          = aws_rds_cluster.database_cluster.database_name
  master_username        = data.aws_secretsmanager_secret_version.database_credentials.secret_string["username"]
  master_user_password   = data.aws_secretsmanager_secret_version.database_credentials.secret_string["password"]
}

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Security group for database"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

resource "aws_s3_bucket_object" "database_backup" {
  bucket = var.database_backup_bucket_name
  key    = "database-backup.sql.gz"
  source = file("./database-backup.sql.gz")
  etag   = filemd5("./database-backup.sql.gz")

  depends_on = [aws_rds_cluster_instance.database_instance]
}