provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "chime_voice_connector_role" {
  name        = "ChimeVoiceConnectorRole"
  description = "Trust role for Chime Voice Connector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chime.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "chime_voice_connector_policy" {
  name   = "ChimeVoiceConnectorPolicy"
  role   = aws_iam_role.chime_voice_connector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "chime:CreateVoiceConnector",
          "chime:GetVoiceConnector",
          "chime:UpdateVoiceConnector",
          "chime:ListTagsForResource"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_chime_voice_connector" "example" {
  name       = "ExampleVoiceConnector"
  host_name  = "example.com"
  self_managed_voice_connector_config {
    enable_media_encryption = true
  }
  tags = {
    Name        = "ExampleVoiceConnector"
    Environment = "dev"
  }
}

resource "aws_chime_voice_connector_logging" "example" {
  voice_connector_id = aws_chime_voice_connector.example.id

  log_level         = "ERROR"
  media_log_config {
    bucket_name = "my-bucket"
    prefix      = "chime-media-logs/"
  }
}