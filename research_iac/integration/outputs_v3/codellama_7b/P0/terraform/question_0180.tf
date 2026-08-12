provider "aws" {
  region = "us-west-2"
}

resource "aws_sagemaker_notebook_instance" "example" {
  name        = "example"
  instance_type = "ml.t2.medium"
  role_arn    = aws_iam_role.example.arn
  kms_key_id  = aws_kms_key.example.arn
}

resource "aws_iam_role" "example" {
  name        = "example"
  description = "IAM role for SageMaker notebook instance"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "sagemaker.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_kms_key" "example" {
  description             = "KMS key for SageMaker notebook instance"
  deletion_window_in_days = 7
}