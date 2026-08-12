provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "dynamodb_table_credentials" {
  name        = "${var.name}-dynamodb-table-credentials"
  description = "Credentials for DynamoDB table ${var.name}"
}

resource "aws_secretsmanager_secret_version" "dynamodb_table_credentials" {
  secret_id     = aws_secretsmanager_secret.dynamodb_table_credentials.id
  secret_string = jsonencode({
    access_key_id     = var.access_key_id
    secret_access_key = var.secret_access_key
  })
}

data "aws_region" "current" {}

resource "aws_dynamodb_table" "example" {
  name           = var.name
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity_units  = 5
  write_capacity_units = 5

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }

  global_secondary_index {
    name            = "${var.name}-gsi-1"
    hash_key        = "id"
    range_key       = "name"
    read_capacity_units  = 5
    write_capacity_units = 5
  }

  replication_region_name = var.replication_region

  server_side_encryption {
    enabled     = true
    kms_master_key_id = aws_kms_key.example.arn
  }
}

resource "aws_dynamodb_table_replica" "example" {
  table_name       = aws_dynamodb_table.example.name
  region          = "us-west-1"
  read_capacity_units  = 5
  write_capacity_units = 5

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }
}

resource "aws_dynamodb_table_replica" "example2" {
  table_name       = aws_dynamodb_table.example.name
  region          = "us-west-2"
  read_capacity_units  = 5
  write_capacity_units = 5

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS key for DynamoDB table ${var.name}"
  deletion_window_in_days = 10
  enable_key_rotation      = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Action    = ["kms:*"]
        Resource  = "*"
        Principal {
          Service = "iam.amazonaws.com"
        }
      },
      {
        Sid       = "Allow DynamoDB to use the key"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt"]
        Resource  = aws_kms_key.example.arn
        Principal {
          Service = "dynamodb.amazonaws.com"
        }
      },
      {
        Sid       = "Allow DynamoDB to use the key for replication"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:Decrypt"]
        Resource  = aws_kms_key.example.arn
        Principal {
          Service = "dynamodb.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_dynamodb_table_policy" "example" {
  name       = "${var.name}-policy"
  table_name = aws_dynamodb_table.example.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow DynamoDB to use the key"
        Effect    = "Allow"
        Action    = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource  = aws_dynamodb_table.example.arn
        Principal {
          Service = "dynamodb.amazonaws.com"
        }
      },
    ]
  })
}