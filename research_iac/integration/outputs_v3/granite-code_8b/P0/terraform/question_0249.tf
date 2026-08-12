provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "chime_voice_connector_role" {
  name               = "chime-voice-connector-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "chime.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "chime_voice_connector_policy_attachment" {
  role       = aws_iam_role.chime_voice_connector_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSIoTLogging"
}

resource "aws_chime_voice_connector" "voice_connector_1" {
  name                = "voice-connector-1"
  encryption_config {
    encryption_type = "KMS"
    key_id          = aws_kms_key.chime_voice_connector_key.arn
  }
}

resource "aws_chime_voice_connector" "voice_connector_2" {
  name                = "voice-connector-2"
  encryption_config {
    encryption_type = "KMS"
    key_id          = aws_kms_key.chime_voice_connector_key.arn
  }
}

resource "aws_chime_voice_connector_group" "voice_connector_group" {
  name            = "voice-connector-group"
  voice_connector = [
    aws_chime_voice_connector.voice_connector_1.id,
    aws_chime_voice_connector.voice_connector_2.id,
  ]
  priority         = 1
}