provider "aws" {
  region = "us-east-1"
}

resource "aws_chime_voice_connector" "example" {
  name = "example-voice-connector"

  encryption_configuration {
    kms_key_id = aws_kms_key.example.arn
  }

  logging_configuration {
    call_analytics_configuration {
      enabled = true
    }

    events_configuration {
      enabled = true
    }

    metrics_configuration {
      enabled = true
    }
  }
}

resource "aws_kms_key" "example" {
  description = "Example KMS key for Chime Voice Connector encryption"
  enable_key_rotation = true
  policy = file("kms_key_policy.json")
}

data "aws_iam_policy_document" "kms_access" {
  statement {
    effect = "Allow"
    actions = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.example.arn]
  }
}

resource "aws_iam_role" "chime_voice_connector" {
  name = "chime-voice-connector-role"

  assume_role_policy = data.aws_iam_policy_document.kms_access.json
}

resource "aws_iam_role_policy_attachment" "chime_voice_connector_kms_access" {
  role = aws_iam_role.chime_voice_connector.name
  policy_arn = data.aws_iam_policy_document.kms_access.arn
}

resource "aws_chime_voice_connector_instance" "example" {
  name = "example-voice-connector-instance"
  voice_connector_id = aws_chime_voice_connector.example.id
  role_arn = aws_iam_role.chime_voice_connector.arn
}