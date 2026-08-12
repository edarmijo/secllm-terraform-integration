provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "example" {
  name = "my-voice-connector"

  encryption_configuration {
    kms_key_id = "YOUR_KMS_KEY_ID"
  }

  logging_configuration {
    enable_media_metrics = true
  }
}