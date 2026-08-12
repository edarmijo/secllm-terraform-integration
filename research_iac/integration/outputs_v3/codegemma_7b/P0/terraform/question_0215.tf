provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "example" {
  cluster_identifier = "my-aurora-cluster"
  engine = "aurora-mysql"
  engine_version = "8.0.27"
  vpc_security_group_ids = ["sg-1234567890abcdef01"]
  subnet_ids = ["subnet-1234567890abcdef01", "subnet-fedcba9876543210"]
  allocated_storage = 20
  storage_type = "gp2"
  database_name = "mydatabase"
  username = "myuser"
  password = "mypassword"
}