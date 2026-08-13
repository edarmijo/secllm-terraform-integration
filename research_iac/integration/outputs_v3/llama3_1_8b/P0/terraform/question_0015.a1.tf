provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eb_ec2_profile" {
  name               = "eb_ec2_profile"
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

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name   = "eb_ec2_profile_policy"
  role   = aws_iam_role.eb_ec2_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "ec2:Describe*",
          "elasticbeanstalk:DescribeEnvironmentResources",
          "elasticbeanstalk:DescribeEvents",
          "elasticbeanstalk:DescribeInstances",
          "elasticbeanstalk:DescribeTaskDefinitions",
          "elasticbeanstalk:GetApplication",
          "elasticbeanstalk:GetConfigurationOption",
          "elasticbeanstalk:GetEnvironment",
          "elasticbeanstalk:GetEnvironmentManagedActions",
          "elasticbeanstalk:GetPlatformVersion",
          "elasticbeanstalk:RegisterApplicationRevision",
          "elasticbeanstalk:SetConfigurationOption",
          "elasticbeanstalk:CreateConfigurationTemplate",
          "elasticbeanstalk:UpdateEnvironment"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_profile_attach" {
  role       = aws_iam_role.eb_ec2_profile.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSServiceRolePolicy"
}

resource "aws_elastic_beanstalk_environment" "prod_env" {
  name                = "prod-env"
  application         = "my-app"
  description         = "Production environment for my app"
  tier                = "webserver-medium"
}

resource "aws_elastic_beanstalk_environment" "staging_env" {
  name                = "stg-env"
  application         = "my-app"
  description         = "Staging environment for my app"
  tier                = "webserver-medium"
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "myuser"
  password             = "mypassword"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.prod_sg.id]
}

resource "aws_db_instance" "staging_db" {
  identifier           = "stg-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "myuser"
  password             = "mypassword"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.staging_sg.id]
}

resource "aws_security_group" "prod_sg" {
  name        = "prod-sg"
  description = "Security group for prod environment"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "staging_sg" {
  name        = "stg-sg"
  description = "Security group for staging environment"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}