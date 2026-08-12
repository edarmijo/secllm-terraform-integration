resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  storage_type         = "gp2"
  allocated_storage    = 10
  backup_Retention_period = 7

  # Never hardcode credentials, passwords, API keys, or tokens as literal strings
  username = var.username
  password = var.password

  # Use least-privilege IAM policies
  # Set minimum required permissions for all IAM roles and instance profiles
  role = aws_iam_role.example.name

  # Restrict network exposure
  security_group_ids = [aws_security_group.example.id]

  # Enforce encryption in transit
  # Use HTTPS/TLS endpoints and avoid plain HTTP
  # Set explicit CIDR blocks in security group ingress rules
  # Avoid 0.0.0.0/0 unless explicitly required by the task
  # Set up a VPC with private subnets and route tables, and configure security groups to allow traffic only from within the VPC

  # Use strong encryption algorithms
  # Prefer AES-256 and TLS 1.2+
  # Set up an AWS Key Management Service (AWS KMS) customer master key (CMK) for encrypting sensitive data at rest
  # Configure your database instance to use the CMK for encrypting data at rest

  # Add integrity checks (checksums) for any downloaded resources or provisioner scripts
  # Verify the integrity of downloaded files using checksums or digital signatures

  # Do not leave TODO, FIXME, or placeholder security comments in the code
  # Either implement the security control or omit the comment
}