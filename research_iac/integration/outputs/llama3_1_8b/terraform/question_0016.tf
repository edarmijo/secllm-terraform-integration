provider "aws" {
  region = "us-west-2"
}

# Create IAM role for Elastic Beanstalk environment
resource "aws_iam_role" "eb_role" {
  name        = "my_ec2_eb_role"
  description = "Elastic Beanstalk Environment Role"

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
resource "aws_iam_policy" "eb_policy" {
  name        = "my_ec2_eb_policy"
  description = "Elastic Beanstalk Environment Policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:RestoreDBInstanceFromDBSnapshot",
        ]
        Effect   = "Allow"
        Resource = aws_rds_instance.my_db.arn
      },
    ]
  })
}

# Create IAM role policy attachment for Elastic Beanstalk environment
resource "aws_iam_role_policy_attachment" "eb_attach" {
  role       = aws_iam_role.eb_role.name
  policy_arn = aws_iam_policy.eb_policy.arn
}

# Create RDS instance and database snapshot
resource "aws_rds_instance" "my_db" {
  allocated_storage     = 20
  engine                = "mysql"
  instance_class        = "db.t2.micro"
  name                  = "my_db"
  username              = "admin"
  password              = "password"
  db_subnet_group_name = aws_db_subnet_group.my_subnet.name

  vpc_security_group_ids = [aws_security_group.my_sg.id]
}

resource "aws_rds_snapshot" "my_snapshot" {
  db_instance_identifier = aws_rds_instance.my_db.id
  snapshot_identifier   = "my_db-snapshot"
}

# Create Elastic Beanstalk environment and application version
resource "aws_elastic_beanstalk_environment" "my_env" {
  name                = "my-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  tier                = "webserver-medium"
  environment_name    = "dev"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = jsonencode([aws_subnet.my_subnet.id])
  }
}

resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-app"
  description = "My Elastic Beanstalk Application"
}

# Create EC2 instance profile
resource "aws_iam_instance_profile" "ec2_eb_profile1" {
  name = "ec2_eb_profile1"

  role = aws_iam_role.eb_role.name
}