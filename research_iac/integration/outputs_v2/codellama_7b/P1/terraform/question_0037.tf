resource "aws_codebuild_project" "example" {
  name        = "example-codebuild-project"
  description = "Example CodeBuild Project"

  service_role = aws_iam_role.example.arn

  source {
    type            = "GITHUB"
    location        = "https://github.com/example/example-repo"
    git_clone_depth = 1
  }

  logs {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.example.name
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "example-codebuild-project-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "example-codebuild-project-logs"
  retention_in_days = 30
}