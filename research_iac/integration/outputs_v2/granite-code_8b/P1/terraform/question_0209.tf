resource "aws_msk_cluster" "example" {
  cluster_name    = "example-cluster"
  number_of_nodes = 3

  # Never hardcode credentials, passwords, API keys, or tokens as literal strings
  # always reference them via var.*, data sources, or AWS Secrets Manager
  broker_node_group_info {
    instance_type = "m5.large"
    client_subnets = [
      aws_subnet.example.id,
    ]
    security_groups = [
      aws_security_group.example.id,
    ]

    # Use least-privilege IAM policies
    # never use '*' in actions or resources unless the task strictly requires it, and prefer specific ARNs
    instance_role_arn = aws_iam_role.example.arn
  }

  configuration_info {
    arn      = aws_msk_configuration.example.arn
    revision = 1
  }

  # Set minimum required permissions for all IAM roles and instance profiles
  # Restrict network exposure
  # set explicit CIDR blocks in security group ingress rules
  # avoid 0.0.0.0/0 unless explicitly required by the task
  # Enforce encryption in transit
  # use HTTPS/TLS endpoints and avoid plain HTTP
  # Use strong encryption algorithms
  # prefer AES-256 and TLS 1.2+

  tags = {
    Environment = "production"
  }
}