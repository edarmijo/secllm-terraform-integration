provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "sagemaker_notebook_instance" {
  secret_id = var.sagemaker_notebook_instance_secret_id
}

variable "environment" {
  type        = string
  description = "Environment name"
}

resource "aws_iam_role" "sagemaker_notebook_instance_execution_role" {
  name        = "${var.environment}-sagemaker-notebook-instance-execution-role"
  description = "Execution role for SageMaker notebook instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_notebook_instance_execution_role_policy" {
  name   = "${var.environment}-sagemaker-notebook-instance-execution-role-policy"
  role   = aws_iam_role.sagemaker_notebook_instance_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = var.notebook_instance_volume_bucket_arn
      },
    ]
  })
}

resource "aws_sagemaker_notebook_instance" "example" {
  name                   = "${var.environment}-sagemaker-notebook-instance"
  instance_type          = "ml.t2.medium"
  role_arn               = aws_iam_role.sagemaker_notebook_instance_execution_role.arn
  notebook_instance_name = var.notebook_instance_name

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "notebook_instance_volume_bucket" {
  bucket        = "${var.environment}-sagemaker-notebook-instance-volume-bucket"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "sagemaker_notebook_instance_sg" {
  name        = "${var.environment}-sagemaker-notebook-instance-sg"
  description = "Security group for SageMaker notebook instance"

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_sagemaker_notebook_instance_lifecycle_config" "example" {
  notebook_instance_name = aws_sagemaker_notebook_instance.example.name

  on_start {
    command = [
      "git clone https://github.com/hashicorp/terraform-provider-aws.git",
      "cd terraform-provider-aws",
      "git checkout main",
      "make build",
    ]
  }
}