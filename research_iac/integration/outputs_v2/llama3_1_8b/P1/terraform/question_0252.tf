provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_chime_voice_connector" "example" {
  name       = "example-voice-connector"
  tags       = var.tags
  voice_connector_code = "arn:aws:chime:${var.region}:${var.account_id}:voice-connector/${aws_chime_voice_connector.example.id}"
}

resource "aws_chime_voice_connector_endpoint" "example" {
  voice_connector_id = aws_chime_voice_connector.example.id
  address            = "sip:example.com"
  ip_address         = "192.0.2.1/32"
}

resource "aws_chime_voice_connector_logging" "example" {
  voice_connector_id = aws_chime_voice_connector.example.id

  log_media_metrics_enabled = true
  media_metrics_policy     = "arn:aws:chime:${var.region}:${var.account_id}:media-metrics-policy/${aws_chime_voice_connector.example.id}"
}

resource "aws_secretsmanager_secret" "example" {
  name        = "example-voice-connector-secret"
  description = "Secret for example voice connector"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "example-user",
    password = "example-password"
  })
}

resource "aws_iam_role" "voice_connector_execution_role" {
  name        = "voice-connector-execution-role-${var.account_id}"
  description = "Execution role for voice connector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chime.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "voice_connector_execution_policy" {
  name   = "voice-connector-execution-policy-${var.account_id}"
  role   = aws_iam_role.voice_connector_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "chime:CreateVoiceConnector",
          "chime:CreateVoiceConnectorEndpoint",
          "chime:UpdateVoiceConnector",
          "chime:UpdateVoiceConnectorEndpoint",
          "secretsmanager:GetSecretValue",
        ]
        Resource = aws_chime_voice_connector.example.id
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "voice_connector_logging_policy" {
  name   = "voice-connector-logging-policy-${var.account_id}"
  role   = aws_iam_role.voice_connector_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "chime:CreateVoiceConnectorLoggingConfiguration",
          "chime:GetVoiceConnectorLoggingConfiguration",
          "cloudwatch:PutMetricData",
        ]
        Resource = aws_chime_voice_connector.example.id
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "voice_connector_execution_profile" {
  name        = "voice-connector-execution-profile-${var.account_id}"
  role        = aws_iam_role.voice_connector_execution_role.id
  depends_on = [aws_iam_role_policy_attachment.voice_connector_execution_policy]
}

resource "aws_iam_role_policy_attachment" "voice_connector_execution_policy" {
  role       = aws_iam_role.voice_connector_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonChimeVoiceConnectorExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "voice_connector_logging_policy" {
  role       = aws_iam_role.voice_connector_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsServiceRolePolicy"
}