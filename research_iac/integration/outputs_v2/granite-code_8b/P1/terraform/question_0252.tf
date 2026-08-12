# Create an AWS Chime Voice Connector with encryption and log media metrics
resource "aws_chime_voice_connector" "example" {
  name = "example-voice-connector"

  encryption_config {
    encryption_type = "KMS"
    key_id          = aws_kms_key.example.arn
  }

  logging_configuration {
    enable_media_metrics = true
  }
}