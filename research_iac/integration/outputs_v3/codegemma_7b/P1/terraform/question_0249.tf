provider "aws" {
  region = "us-east-1"
}

variable "connector_name1" {
  type = string
}

variable "connector_name2" {
  type = string
}

resource "aws_chime_voice_connector" "connector1" {
  name = var.connector_name1
  encryption_configuration {
    encryption_type = "TLS_1_2"
  }
}

resource "aws_chime_voice_connector" "connector2" {
  name = var.connector_name2
  encryption_configuration {
    encryption_type = "TLS_1_2"
  }
}

resource "aws_chime_voice_connector_group" "group" {
  name = "VoiceConnectorGroup"

  voice_connector {
    connector_id = aws_chime_voice_connector.connector1.id
    priority = 1
  }

  voice_connector {
    connector_id = aws_chime_voice_connector.connector2.id
    priority = 2
  }
}