provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "memcached_password" {
  name = "memcached-password"
}

data "aws_secretsmanager_secret_version" "memcached_password" {
  secret_id = data.aws_secretsmanager_secret.memcached_password.id
}

resource "aws_iam_role" "memcached_cluster" {
  name        = "memcached-cluster-role"
  description = "Role for Memcached Cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "memcached_cluster" {
  name   = "memcached-cluster-policy"
  role   = aws_iam_role.memcached_cluster.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.memcached_cluster.arn
      },
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "memcached_cluster" {
  name = "memcached-cluster-profile"
  role = aws_iam_role.memcached_cluster.name
}

resource "aws_security_group" "memcached_cluster" {
  name        = "memcached-cluster-sg"
  description = "Security Group for Memcached Cluster"

  ingress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "memcached_cluster" {
  bucket = "memcached-cluster-bucket"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_memcached_cluster" "example" {
  cluster_name           = "memcached-cluster"
  num_nodes              = 1
  parameter_group_name   = "default.memcached1.4"
  security_groups        = [aws_security_group.memcached_cluster.id]
  port                  = 11211

  maintenance_window    = "sun:03:00-sun:04:00"
  preferred_maintenance_window = "sun:02:30-sun:03:30"

  notification_topic_arn = aws_sns_topic.memcached_notifications.arn
}

resource "aws_sns_topic" "memcached_notifications" {
  name = "memcached-notifications-topic"
}

resource "aws_s3_bucket_object" "memcached_config" {
  bucket = aws_s3_bucket.memcached_cluster.id

  key    = "config.json"
  source = file("${path.module}/config.json")

  etag = filemd5("${path.module}/config.json")
}