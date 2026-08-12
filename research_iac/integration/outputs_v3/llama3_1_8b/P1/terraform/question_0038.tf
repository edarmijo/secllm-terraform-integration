provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "codebuild_project" {
  secret_id = "codebuild-project-credentials"
}

locals {
  codebuild_project_name = "example-codebuild-project"
  codebuild_role_name    = "example-codebuild-role"
  codebuild_source_type  = "GITHUB"
  codebuild_source_url   = "https://github.com/username/repository.git"
  codebuild_artifacts_type = "CODEBUILD_PROJECT_OUTPUTS"
}

resource "aws_iam_role" "codebuild_role" {
  name               = local.codebuild_role_name
  description        = "CodeBuild service role for ${local.codebuild_project_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${local.codebuild_role_name}-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.codebuild_artifacts.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCodeBuildServiceRole"
}

resource "aws_codebuild_project" "example" {
  name         = local.codebuild_project_name
  description  = "Example CodeBuild project"
  build_spec   = file("./buildspec.yml")
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = local.codebuild_artifacts_type
    location = aws_s3_bucket.codebuild_artifacts.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0-ubuntu"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "CODEBUILD_PROJECT_NAME"
      value = local.codebuild_project_name
    }
  }
}

resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket = "${local.codebuild_project_name}-artifacts"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_codebuild_source_credentials" "example" {
  name     = local.codebuild_project_name
  type     = local.codebuild_source_type
  provider = aws_iam_role.codebuild_role

  connection_arn = aws_codecommit_repository.example.arn
}

resource "aws_codecommit_repository" "example" {
  repository_name = "${local.codebuild_project_name}-repo"
}