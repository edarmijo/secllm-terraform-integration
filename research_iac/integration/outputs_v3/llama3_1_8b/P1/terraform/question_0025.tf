provider "aws" {
  region = var.region
}

# Create a secret for the RDS database password
resource "aws_secretsmanager_secret" "rds_password" {
  name = "rds_password"
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({"password": var.rds_password})
}

# Create IAM roles and instance profiles
resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_role"
  description = "Elastic Beanstalk EC2 role"

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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb_ec2_policy"
  role   = aws_iam_role.eb_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:DeleteObjectVersion",
          "s3:PutObjectVersionAcl",
          "s3:GetObjectVersionAcl",
          "s3:PutObjectVersion",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:DeleteObjectVersion",
          "s3:PutObjectVersionAcl",
          "s3:GetObjectVersionAcl",
          "s3:PutObjectVersion",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
        ]
        Resource = [
          aws_s3_bucket.myapp_us_east.arn,
          aws_s3_bucket.myapp_eu_west.arn,
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBClusterSnapshots",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "rds:CreateDBSnapshot",
          "rds:CreateDBClusterSnapshot",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBClusterSnapshot",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
          "rds:StartDBInstance",
          "rds:StartDBCluster",
          "rds:StopDBInstance",
          "rds:StopDBCluster",
          "rds:RebootDBInstance",
          "rds:RebootDBCluster",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBClusterFromDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBClusterFromDBSnapshot",
          "rds:CreateDBInstanceReadReplica",
          "rds:CreateDBClusterReadReplica",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "rds:CreateDBSnapshot",
          "rds:CreateDBClusterSnapshot",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBClusterSnapshot",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
          "rds:StartDBInstance",
          "rds:StartDBCluster",
          "rds:StopDBInstance",
          "rds:StopDBCluster",
          "rds:RebootDBInstance",
          "rds:RebootDBCluster",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBClusterFromDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBClusterFromDBSnapshot",
          "rds:CreateDBInstanceReadReplica",
          "rds:CreateDBClusterReadReplica",
        ]
        Resource = [
          aws_rds_cluster.main_db_us_east.arn,
          aws_rds_cluster.main_db_eu_west.arn,
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateVpc",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSubnet",
          "ec2:DeleteVpc",
          "ec2:ModifySecurityGroup",
          "ec2:ModifySubnet",
          "ec2:ModifyVpc",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateVpc",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSubnet",
          "ec2:DeleteVpc",
          "ec2:ModifySecurityGroup",
          "ec2:ModifySubnet",
          "ec2:ModifyVpc",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
        ]
        Resource = [
          aws_security_group.myenv_us_east.arn,
          aws_security_group.myenv_eu_west.arn,
        ]
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile3" {
  name = "eb_ec2_profile3"
  role = aws_iam_role.eb_ec2_role.name
}

# Create Elastic Beanstalk environments
resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name                = "myenv_us_east"
  application         = aws_elastic_beanstalk_application.myapp_us_east.name
  environment_name    = "myenv_us_east"
  tier_name           = "WebServer"
  version_label       = "myenv_us_east"
  platform            = "64bit Amazon Linux 2 v3.2.10 running Docker"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.myenv_us_east.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet.myenv_us_east.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = jsonencode([aws_subnet