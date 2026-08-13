provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "sagemaker-execution-role" {
  name        = "SageMakerExecutionRole"
  description = "Trust role for SageMaker execution"

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

resource "aws_iam_role_policy_attachment" "sagemaker-execution-role-policy-attachment" {
  role       = aws_iam_role.sagemaker-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

data "archive_file" "notebook-image" {
  type        = "zip"
  source_file = "https://github.com/hashicorp/terraform-provider-aws/raw/main/examples/sagemaker/notebook.zip"
  output_path = "${path.module}/notebook-image.zip"
}

resource "aws_s3_bucket" "sagemaker-notebook-bucket" {
  bucket = "sagemaker-notebook-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_object" "notebook-image-object" {
  bucket = aws_s3_bucket.sagemaker-notebook-bucket.id
  key    = "notebook-image.zip"
  source = "${path.module}/notebook-image.zip"
}

resource "aws_sagemaker_notebook_instance" "sagemaker-notebook-instance" {
  name                = "SageMakerNotebookInstance"
  role_arn            = aws_iam_role.sagemaker-execution-role.arn
  instance_type       = "ml.t2.medium"
  notebook_instance_policy_name = "SageMakerNotebookPolicy"

  vpc_config {
    subnet_id = "subnet-12345678"
  }

  tags = {
    Name        = "SageMaker Notebook Instance"
    Environment = "dev"
  }
}