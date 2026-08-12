provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "autograder_role" {
  name = "autograder-role"

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

resource "aws_iam_role_policy" "autograder_policy" {
  name = "autograder-policy"
  role = aws_iam_role.autograder_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::student-code",
        "arn:aws:s3:::autograder-results"
      ]
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "autograder_project" {
  name = "autograder-project"

  source {
    type = "GITHUB"
    location = "github.com/username/repo"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:latest"
  }

  build_spec {
    version = "0.2"
    phases {
      build {
        commands = [
          "cd student-code",
          "make test"
        ]
      }
    }
  }

  artifacts {
    type = "S3"
    location = "autograder-results"
  }

  role = aws_iam_role.autograder_role.arn
}