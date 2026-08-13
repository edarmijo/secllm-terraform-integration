resource "aws_codebuild_project" "example" {
  name           = "example-codebuild-project"
  service_role   = aws_iam_role.codebuild.arn
  source_control = {
    type            = "github"
    location        = "https://github.com/example/example-repo.git"
    git_clone_depth = 1
  }

  artifacts {
    type = "s3"

    bucket_owner       = "aws"
    bucket             = "aws-codebuild-us-east-1"
    path               = "example-output"
    encryption_key     = aws_kms_key.example.arn
    build_context      = true
    override_artifact_name = false
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:4.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "CODEBUILD_INIT_COMMAND"
      value = "echo Hello, World!"
    }
  }

  logs_config {
    cloudwatch_logs {
      status  = "ENABLED"
      group   = aws_cloudwatch_log_group.example.name
      stream  = aws_cloudwatch_log_stream.example.name
    }

    s3_logs {
      status         = "ENABLED"
      bucket         = aws_s3_bucket.example.bucket
      prefix         = "codebuild-logs"
      encryption_key = aws_kms_key.example.arn
    }
  }

  secondary_sources {
    type            = "github"
    location        = "https://github.com/example/example-secondary-repo.git"
    git_clone_depth = 1

    auth {
      type     = "OAUTH"
      resource = "arn:aws:codecommit:us-east-1:123456789012:MyGitHubRepo"

      # Replace with your GitHub personal access token.
      # See https://docs.aws.amazon.com/codebuild/latest/userguide/github-oauth-token.html
      # for more information on how to generate a GitHub personal access token.
      token = "your_github_personal_access_token"
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "example-codebuild-role"

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

  inline_policy {
    name = "CodeBuildPolicy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ],
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::example-bucket/*"
      ],
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  }
}