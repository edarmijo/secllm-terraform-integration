provider "aws" {
  region = var.region
}

resource "aws_lightsail_database" "example" {
  name          = "example-db"
  engine        = "mysql"
  version       = "5.7"
  skip_final_snapshot = true

  backup {
    enabled      = true
    retention    = 7
    rotation_day = 1
  }

  ca_cert_identifier = "aws-root"
}