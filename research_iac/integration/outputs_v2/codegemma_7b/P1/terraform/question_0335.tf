provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "airbyte_connector_test_db" {
  engine = "postgresql15"
  engine_mode = "serverless"
  allocated_storage = 5
  instance_type = "db.t3.micro"

  vpc_security_group_ids = ["sg-0123456789abcdef01"]
  subnet_ids = ["subnet-0123456789abcdef02", "subnet-0123456789abcdef03"]

  tags = {
    Name = "airbyte-connector-test-db"
  }
}