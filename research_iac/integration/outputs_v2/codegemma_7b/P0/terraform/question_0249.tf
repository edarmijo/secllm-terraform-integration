provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "connector1" {
  name = "Connector1"
  encryption_configuration {
    require_encryption = true
  }
}

resource "aws_chime_voice_connector" "connector2" {
  name = "Connector2"
  encryption_configuration {
    require_encryption = true
  }
}

resource "aws_chime_voice_connector_group" "group" {
  name = "ConnectorGroup"

  voice_connector {
    connector_id = aws_chime_voice_connector.connector1.id
    priority = 1
  }

  voice_connector {
    connector_id = aws_chime_voice_connector.connector2.id
    priority = 2
  }
}