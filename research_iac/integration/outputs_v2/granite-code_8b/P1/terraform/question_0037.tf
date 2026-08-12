resource "aws_codebuild_project" "example" {
  name           = "example-project"
  service_role   = aws_iam_role.codebuild.arn
  build_spec     = file("build-spec.yml")

  source {
    type      = "GITHUB"
    location  = "https://github.com/example/repo.git"
    git_clone_depth = 1
  }

  artifacts {
    type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "example-stream"
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}