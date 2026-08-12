provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "example" {
  name                   = "Example Voice Connector"
  encryption             = true
  log_media_metrics      = true
  require_encryption     = true
  allow_external_media   = false
}