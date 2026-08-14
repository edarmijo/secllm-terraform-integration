resource "aws_sagemaker_notebook_instance" "example" {
  name               = "my-notebook-instance"
  instance_type      = "ml.t2.medium"
  role_arn            = aws_iam_role.example.arn
}

resource "aws_iam_role" "example" {
  name = "my-sagemaker-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sagemaker.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}