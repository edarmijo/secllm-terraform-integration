resource "aws_codebuild_project" "example" {
  name        = "example-codebuild-project"
  description = "An example CodeBuild project"

  service_role = aws_iam_role.example.arn

  source {
    type            = "GITHUB"
    location        = "https://github.com/example/example-repo.git"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      status       = "ENABLED"
      group_name   = "/aws/codebuild/${var.project_name}"
      stream_name  = "example-stream"
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "example-codebuild-role"
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
}