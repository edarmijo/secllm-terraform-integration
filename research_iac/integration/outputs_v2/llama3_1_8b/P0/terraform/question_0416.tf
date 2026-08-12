provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "database_restore_role" {
  name        = "database-restore-role"
  description = "Role for restoring a database from S3"

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

resource "aws_iam_policy" "database_restore_policy" {
  name        = "database-restore-policy"
  description = "Policy for restoring a database from S3"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "rds:RestoreDBInstanceFromS3Backup"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "database_restore_attach" {
  role       = aws_iam_role.database_restore_role.name
  policy_arn = aws_iam_policy.database_restore_policy.arn
}

resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = "example-cluster"
  database_name           = "mydb"
  instance_class          = "db.t2.micro"
  engine                  = "aurora-mysql"
  port                    = 3306

  vpc_security_group_ids = [aws_security_group.example.id]

  iam_instance_profile {
    name = aws_iam_role.database_restore_role.name
  }

  depends_on = [
    aws_db_cluster_parameter_group.example,
    aws_rds_cluster_parameter_group.example
  ]
}

resource "aws_s3_bucket" "example" {
  bucket = "mydb-backup"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_rds_cluster_snapshot" "example" {
  cluster_identifier      = aws_rds_cluster_instance.example.cluster_identifier
  snapshot_set_id        = "arn:aws:rds:us-west-2:123456789012:snapshot-set:mydb-backup"
  source_db_cluster_snapshot_identifier = "arn:aws:rds:us-west-2:123456789012:snapshot:mydb-backup"
}