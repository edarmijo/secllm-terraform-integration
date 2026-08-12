provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_codebuild_project" "autograder" {
  name         = "cs-class-autograder"
  description  = "Autograder for CS class"
  source_type  = "GITHUB"
  source_config {
    repository_name       = var.github_repo
    connection_arn        = aws_codecommit_repository.cs_class.arn
    branch                = "main"
  }
  environment {
    type            = " LINUX_CONTAINER "
    compute_type    = " BUILD_GENERAL1_SMALL "
    image           = "aws/codebuild/docker:17.12.0-nodejs-14"
    privileged_mode = true
  }
}

resource "aws_codecommit_repository" "cs_class" {
  name        = "cs-class-autograder-repo"
  description = "Repository for CS class autograder"
}

resource "aws_iam_role" "codebuild_autograder" {
  name               = "codebuild-autograder-execution-role"
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

resource "aws_iam_role_policy" "codebuild_autograder_policy" {
  name   = "codebuild-autograder-execution-policy"
  role   = aws_iam_role.codebuild_autograder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetBlob",
          "codecommit:GetObject",
        ]
        Effect   = "Allow"
        Resource = aws_codecommit_repository.cs_class.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_token_policy" {
  name   = "github-token-execution-policy"
  role   = aws_iam_role.codebuild_autograder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "github.com"
        }
        Condition = {
          StringEquals = {
            "ForAnyValue:aws:PrincipalTag/Type" : "codebuild"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_token_attach" {
  role       = aws_iam_role.codebuild_autograder.id
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildGitHubToken"
}

resource "aws_security_group" "autograder_sg" {
  name        = "cs-class-autograder-sg"
  description = "Security group for CS class autograder"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_codebuild_project_source" "github_token" {
  project_name = aws_codebuild_project.autograder.name
  source_type  = "GITHUB_TOKEN"

  github_token {
    token     = var.github_token
    owner     = var.github_owner
    repo      = var.github_repo
    branch    = "main"
  }
}

resource "aws_s3_bucket" "autograder_results" {
  bucket        = "cs-class-autograder-results"
  acl           = "private"

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

resource "aws_s3_bucket_policy" "autograder_results_policy" {
  bucket = aws_s3_bucket.autograder_results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.autograder_results.arn}/*"
      },
    ]
  })
}