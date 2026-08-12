provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "example" {
  name                   = "ExampleVoiceConnector"
  encryption             = true
  log_media_metrics      = true
}