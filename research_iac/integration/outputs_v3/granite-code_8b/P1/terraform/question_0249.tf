provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

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

resource "aws_iam_role_policy" "chime_voice_connector_policy" {
  name   = "chime-voice-connector-policy"
  role   = aws_iam_role.chime_voice_connector_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket/*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_chime_voice_connector" "primary" {
  name            = "PrimaryVoiceConnector"
  encryption      = true
  aws_account_id  = data.aws_caller_identity.current.account_id
  logging_role    = aws_iam_role.chime_voice_connector_role.arn
}

resource "aws_chime_voice_connector" "secondary" {
  name            = "SecondaryVoiceConnector"
  encryption      = true
  aws_account_id  = data.aws_caller_identity.current.account_id
  logging_role    = aws_iam_role.chime_voice_connector_role.arn
}

resource "aws_chime_voice_connector_group" "example" {
  name            = "VoiceConnectorGroup"
  voice_connector_ids = [
    aws_chime_voice_connector.primary.id,
    aws_chime_voice_connector.secondary.id
  ]
  priority         = 1
}