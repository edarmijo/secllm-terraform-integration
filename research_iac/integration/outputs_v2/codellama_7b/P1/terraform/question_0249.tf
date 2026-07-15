provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "chime_voice_connector_role" {
  name               = "ChimeVoiceConnectorRole"
  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")
}

resource "aws_iam_instance_profile" "chime_voice_connector_instance_profile" {
  name = "ChimeVoiceConnectorInstanceProfile"
  role = aws_iam_role.chime_voice_connector_role.name
}

resource "aws_chime_voice_connector" "chime_voice_connector1" {
  name                   = "ChimeVoiceConnector1"
  encryption             = true
  require_encryption     = true
  instance_profile       = aws_iam_instance_profile.chime_voice_connector_instance_profile.name
  security_group_ids     = [aws_security_group.chime_voice_connector_sg.id]
}

resource "aws_chime_voice_connector" "chime_voice_connector2" {
  name                   = "ChimeVoiceConnector2"
  encryption             = true
  require_encryption     = true
  instance_profile       = aws_iam_instance_profile.chime_voice_connector_instance_profile.name
  security_group_ids     = [aws_security_group.chime_voice_connector_sg.id]
}

resource "aws_security_group" "chime_voice_connector_sg" {
  name        = "ChimeVoiceConnectorSG"
  description = "Security group for Chime Voice Connectors"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_chime_voice_connector_group" "chime_voice_connector_group" {
  name                   = "ChimeVoiceConnectorGroup"
  priority               = 1
  voice_connectors       = [aws_chime_voice_connector.chime_voice_connector1.id, aws_chime_voice_connector.chime_voice_connector2.id]
}