resource "aws_codebuild_project" "example" {
  name = "example-project"

  source {
    type = "GITHUB"
    location = "github.com/example-user/example-repo.git"
    git_clone_depth = 1
  }

  role_arn = aws_iam_role.example.arn

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
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