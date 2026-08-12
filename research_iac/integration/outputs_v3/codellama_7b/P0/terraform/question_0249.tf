provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "example_1" {
  name                   = "Example Voice Connector 1"
  encryption             = true
  require_encryption     = true
  priority_weight        = 10
}

resource "aws_chime_voice_connector" "example_2" {
  name                   = "Example Voice Connector 2"
  encryption             = true
  require_encryption     = true
  priority_weight        = 5
}

resource "aws_chime_voice_connector_group" "example" {
  name                   = "Example Voice Connector Group"
  voice_connectors       = [aws_chime_voice_connector.example_1.id, aws_chime_voice_connector.example_2.id]
  priority               = ["example_1", "example_2"]
}