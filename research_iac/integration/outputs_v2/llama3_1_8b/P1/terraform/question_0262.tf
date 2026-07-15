provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_group" "example" {
  name = "ExampleGroup"
}

resource "aws_iam_group_policy_attachment" "example" {
  group      = aws_iam_group.example.name
  policy_arn = aws_iam_policy.example.arn
}

resource "aws_iam_policy" "example" {
  name        = "ExamplePolicy"
  description = "An example policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEC2Access"
        Effect    = "Allow"
        Action    = ["ec2:Describe*"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "example" {
  name = "ExampleSecret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "exampleuser",
    password = "examplepassword"
  })
}

data "aws_iam_policy_document" "example" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect   = "Allow"

    condition {
      test     = "StringEquals"
      values    = [aws_iam_openidconnectprovider.example.url]
      variable  = "identity.provider.id"
    }

    principals {
      identifiers = [aws_iam_openidconnectprovider.example.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "ExampleRole"
  assume_role_policy = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}