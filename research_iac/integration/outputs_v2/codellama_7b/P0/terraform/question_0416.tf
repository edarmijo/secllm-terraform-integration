provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  backup_retention_days= 7
  skip_final_snapshot  = true
}

resource "aws_s3_bucket" "example" {
  bucket = "my-db-backups"
}

resource "aws_s3_bucket_object" "example" {
  bucket = aws_s3_bucket.example.id
  key    = "mydb.sql"
  source = "/path/to/mydb.sql"
}

resource "aws_iam_role" "example" {
  name        = "MyDbRestoreRole"
  description = "Allows for restoring a database from an S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "example" {
  name        = "MyDbRestorePolicy"
  description = "Allows for restoring a database from an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}