provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Create IAM role for Elastic Beanstalk environment
resource "aws_iam_role" "eb_env_role" {
  name               = "myenv-eb-env-role"
  description        = "Elastic Beanstalk environment role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM policy for Elastic Beanstalk environment
resource "aws_iam_policy" "eb_env_policy" {
  name        = "myenv-eb-env-policy"
  description = "Elastic Beanstalk environment policy"

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
        Resource = aws_s3_bucket.eb_env_bucket.arn
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eb_env_attach" {
  role       = aws_iam_role.eb_env_role.name
  policy_arn = aws_iam_policy.eb_env_policy.arn
}

# Create IAM instance profile for Elastic Beanstalk environment
resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name        = "myenv-eb-ec2-profile"
  description = "Elastic Beanstalk EC2 instance profile"

  role = aws_iam_role.eb_env_role.name
}

# Create S3 bucket for Elastic Beanstalk environment
resource "aws_s3_bucket" "eb_env_bucket" {
  bucket = "myenv-eb-env-bucket"
  acl    = "private"
}

# Create Route 53 hosted zone
resource "aws_route53_zone" "myapp_domain" {
  name            = "myapp.com"
  comment         = "Managed by Terraform"
}

# Create Route 53 record set for Elastic Beanstalk environment
resource "aws_route53_record_set" "eb_env_record" {
  zone_id = aws_route53_zone.myapp_domain.zone_id
  name    = "myenv.myapp.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv.name
    zone_id                = aws_elastic_beanstalk_environment.myenv.id
    evaluate_target_health = true
  }
}

# Create Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "myenv" {
  name                = "myenv"
  application_name   = "myapp"
  solution_stack_name = "64bit Amazon Linux 2 v3.0.5 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = jsonencode([aws_subnet.default.id])
  }
}

# Create RDS database instance
resource "aws_rds_cluster_instance" "myapp_db" {
  cluster_identifier      = aws_rds_cluster.myapp_db.name
  engine                  = "mysql"
  instance_class          = "db.t2.micro"
  db_instance_identifier  = "myapp-db-1"
}

# Create RDS database cluster
resource "aws_rds_cluster" "myapp_db" {
  cluster_identifier      = "myapp-db-cluster"
  engine                  = "mysql"
  master_username         = var.rds_master_username
  master_password         = aws_secretsmanager_secret.myapp_db_secret.secret_string
}

# Create AWS Secrets Manager secret for RDS database credentials
resource "aws_secretsmanager_secret" "myapp_db_secret" {
  name = "myapp-db-secret"
}

# Store RDS database credentials in Secrets Manager
resource "aws_secretsmanager_secret_version" "myapp_db_secret_version" {
  secret_id     = aws_secretsmanager_secret.myapp_db_secret.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = aws_secretsmanager_secret.myapp_db_secret.secret_string
  })
}

# Configure network security for Elastic Beanstalk environment
resource "aws_security_group" "eb_env_sg" {
  name        = "myenv-eb-env-sg"
  description = "Elastic Beanstalk environment security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure network security for RDS database instance
resource "aws_security_group" "myapp_db_sg" {
  name        = "myapp-db-sg"
  description = "RDS database security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}