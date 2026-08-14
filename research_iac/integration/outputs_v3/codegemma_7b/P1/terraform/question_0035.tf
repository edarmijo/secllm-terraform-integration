resource "aws_codebuild_project" "example" {
  name = "example-project"

  role = aws_iam_role.example.arn

  environment {
    variables {
      MY_SECRET = var.my_secret_value
    }
  }

  build_spec = file("buildspec.yml")

  source {
    type = "NO_SOURCE"
  }
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy {
    name = "AmazonCodeBuildReadOnlyAccess"
  }
}

variable "my_secret_value" {
  type = string
  sensitive = true
}