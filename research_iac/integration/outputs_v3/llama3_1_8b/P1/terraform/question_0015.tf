# Create IAM roles for Elastic Beanstalk environments
resource "aws_iam_role" "eb_production" {
  name        = "eb_production"
  description = "Elastic Beanstalk production environment role"

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

resource "aws_iam_role" "eb_staging" {
  name        = "eb_staging"
  description = "Elastic Beanstalk staging environment role"

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

# Create IAM instance profiles for Elastic Beanstalk environments
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role = aws_iam_role.eb_production.name
}

# Create RDS instances for production and staging databases
resource "aws_db_instance" "prod_db" {
  identifier           = "prod-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = var.prod_db_username
  password             = aws_secretsmanager_secret.prod_db_password.arn
  vpc_security_group_ids = [aws_security_group.prod_sg.id]
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = var.staging_db_username
  password             = aws_secretsmanager_secret.staging_db_password.arn
  vpc_security_group_ids = [aws_security_group.staging_sg.id]
}

# Create security groups for production and staging environments
resource "aws_security_group" "prod_sg" {
  name        = "prod-sg"
  description = "Security group for production environment"

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

resource "aws_security_group" "staging_sg" {
  name        = "staging-sg"
  description = "Security group for staging environment"

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

# Create Elastic Beanstalk environments
resource "aws_elastic_beanstalk_environment" "prod_env" {
  name                = "prod-env"
  application         = aws_elastic_beanstalk_application.prod_app.name
  environment_name    = "prod-env"
  tier                = "webserver-medium"
  version_label       = "v1"
  settings           = jsonencode({
    "aws:elasticbeanstalk:environment:region" = var.region
  })
}

resource "aws_elastic_beanstalk_environment" "staging_env" {
  name                = "staging-env"
  application         = aws_elastic_beanstalk_application.staging_app.name
  environment_name    = "staging-env"
  tier                = "webserver-medium"
  version_label       = "v1"
  settings           = jsonencode({
    "aws:elasticbeanstalk:environment:region" = var.region
  })
}

# Create Elastic Beanstalk applications
resource "aws_elastic_beanstalk_application" "prod_app" {
  name        = "prod-app"
  description = "Production application"
}

resource "aws_elastic_beanstalk_application" "staging_app" {
  name        = "staging-app"
  description = "Staging application"
}