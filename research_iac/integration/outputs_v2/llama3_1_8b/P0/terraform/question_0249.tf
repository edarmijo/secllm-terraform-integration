provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "voice_connector_role" {
  name        = "voice_connector_role"
  description = "Role for voice connectors"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "aws_iam_role_policy" "voice_connector_policy" {
  name   = "voice_connector_policy"
  role   = aws_iam_role.voice_connector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "chime:CreateVoiceConnector",
          "chime:UpdateVoiceConnector",
          "chime:DeleteVoiceConnector",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_chime_voice_connector" "voice_connector_1" {
  name       = "voice-connector-1"
  region     = "us-west-2"
  encryption = true
}

resource "aws_chime_voice_connector" "voice_connector_2" {
  name       = "voice-connector-2"
  region     = "us-west-2"
  encryption = true
}

resource "aws_chime_voice_connector_group" "voice_connector_group" {
  name        = "voice-connector-group"
  voice_connector_group_type = "FIFO"

  voice_connectors = [
    aws_chime_voice_connector.voice_connector_1.id,
    aws_chime_voice_connector.voice_connector_2.id
  ]

  priority_order = [aws_chime_voice_connector.voice_connector_1.id, aws_chime_voice_connector.voice_connector_2.id]
}