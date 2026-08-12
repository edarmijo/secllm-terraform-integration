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

resource "aws_iam_policy" "autograder_policy" {
  name = "autograder-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds",
        "codebuild:ListBuilds",
        "codebuild:CreateWebhook",
        "codebuild:DeleteWebhook",
        "codebuild:ListWebhooks",
        "codebuild:GetWebhook",
        "codebuild:UpdateWebhook",
        "codebuild:BatchDeleteBuilds",
        "codebuild:ListSourceCredentials",
        "codebuild:CreateSourceCredential",
        "codebuild:DeleteSourceCredential",
        "codebuild:GetSourceCredential",
        "codebuild:UpdateSourceCredential",
        "codebuild:ListProjects",
        "codebuild:CreateProject",
        "codebuild:DeleteProject",
        "codebuild:GetProject",
        "codebuild:UpdateProject",
        "codebuild:BatchGetProjects",
        "codebuild:ListBuildsForProject",
        "codebuild:ListArtifacts",
        "codebuild:BatchGetArtifacts",
        "codebuild:DownloadArtifacts",
        "codebuild:DeleteArtifacts",
        "codebuild:ListTagsForResource",
        "codebuild:TagResource",
        "codebuild:UntagResource"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "autograder_policy_attachment" {
  role       = aws_iam_role.autograder_role.name
  policy_arn = aws_iam_policy.autograder_policy.arn
}

resource "aws_codebuild_project" "autograder_project" {
  name = "autograder-project"

  source {
    type = "GITHUB"
    location = "github.com/<username>/<repository>.git"
    git_clone_depth = 1
  }

  environment {
    name = "autograder-environment"
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:latest"
  }

  build_spec {
    version = 0.2
    phases {
      build {
        commands {
          # Run student code here
        }
      }
    }
  }

  artifacts {
    type = "S3"
    location = "s3://<bucket-name>/autograder-artifacts"
  }
}