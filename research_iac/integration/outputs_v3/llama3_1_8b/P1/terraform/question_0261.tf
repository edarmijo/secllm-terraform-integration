provider "aws" {
  region = var.region
}

data "aws_secretsmanager_secret" "iam_users_passwords" {
  name = "iam-users-passwords"
}

resource "aws_iam_group" "basic_group" {
  name = "BasicGroup"
}

resource "aws_iam_user" "user1" {
  username = "user1"
  group    = aws_iam_group.basic_group.name
  provider = aws

  lifecycle {
    ignore_changes = [password]
  }
}

resource "aws_iam_user_password_policy" "policy" {
  password_policy {
    minimum_length    = 12
    require_symbols   = true
    require_numbers   = true
    require_uppercase = true
  }

  provider = aws
}

resource "aws_iam_user_login_profile" "user1_login_profile" {
  user        = aws_iam_user.user1.username
  password    = data.aws_secretsmanager_secret_version.iam_users_passwords.secret_string
  pgp_key      = var.pgp_key
  provider    = aws

  lifecycle {
    ignore_changes = [password]
  }
}

resource "aws_iam_user" "user2" {
  username = "user2"
  group    = aws_iam_group.basic_group.name
  provider = aws

  lifecycle {
    ignore_changes = [password]
  }
}

resource "aws_iam_user_login_profile" "user2_login_profile" {
  user        = aws_iam_user.user2.username
  password    = data.aws_secretsmanager_secret_version.iam_users_passwords.secret_string
  pgp_key      = var.pgp_key
  provider    = aws

  lifecycle {
    ignore_changes = [password]
  }
}