provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

resource "aws_iam_role" "s3_glacier_vault" {
  name        = "${var.prefix}-s3-glacier-vault-role"
  description = "Role for S3 Glacier vault access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glacier.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3_glacier_vault_policy" {
  name        = "${var.prefix}-s3-glacier-vault-policy"
  description = "Policy for S3 Glacier vault access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3GlacierVaultAccess"
        Effect    = "Allow"
        Action    = ["glacier:GetJobTicket", "glacier:ListJobs", "glacier:GetVaultNotifications"]
        Resource  = "${aws_glacier_vault.s3_glacier_vault.id}"
      },
      {
        Sid       = "AllowS3GlacierVaultAccessLogDelivery"
        Effect    = "Allow"
        Action    = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource  = "${aws_cloudwatch_log_group.s3_glacier_vault_access_logs.arn}"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_glacier_vault_attach" {
  role       = aws_iam_role.s3_glacier_vault.name
  policy_arn = aws_iam_policy.s3_glacier_vault_policy.arn
}

resource "aws_glacier_vault" "s3_glacier_vault" {
  name        = "${var.prefix}-s3-glacier-vault"
  description = "S3 Glacier vault for ${var.prefix}"
}

resource "aws_cloudwatch_log_group" "s3_glacier_vault_access_logs" {
  name              = "${var.prefix}-s3-glacier-vault-access-logs"
  retention_in_days = 30
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_attach" {
  role       = aws_iam_role.s3_glacier_vault.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsServiceRolePolicy"
}