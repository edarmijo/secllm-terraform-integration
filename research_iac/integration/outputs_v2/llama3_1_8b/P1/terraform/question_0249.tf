provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "chime_api_key" {
  secret_id = var.chime_api_key_secret_id
}

locals {
  chime_api_key = jsondecode(data.aws_secretsmanager_secret_version.chime_api_key.secret_string)
}

resource "aws_chime_voice_connector" "voice_connector_1" {
  name        = "voice-connector-1"
  require_encryption_for_media = true

  security_profile {
    media_mode = "secured"
  }
}

resource "aws_chime_voice_connector" "voice_connector_2" {
  name        = "voice-connector-2"
  require_encryption_for_media = true

  security_profile {
    media_mode = "secured"
  }
}

resource "aws_chime_voice_connector_group" "voice_connector_group" {
  name       = "voice-connector-group"
  voice_connector_arns = [aws_chime_voice_connector.voice_connector_1.arn, aws_chime_voice_connector.voice_connector_2.arn]

  priority_order = [
    aws_chime_voice_connector.voice_connector_1.arn,
    aws_chime_voice_connector.voice_connector_2.arn
  ]
}

resource "aws_security_group" "voice_connector_sg" {
  name        = "voice-connector-sg"
  description = "Security group for voice connectors"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}