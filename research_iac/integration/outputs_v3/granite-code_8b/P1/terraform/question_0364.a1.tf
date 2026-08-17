resource "aws_lightsail_instance" "example" {
  name            = "example-instance"
  availability_zone = "us-east-1a"
  blueprint_id    = "linux_ubuntu_18_04"
  bundle_id       = "virtual_private_server_2gb"

  # Never hardcode credentials, passwords, API keys, or tokens as literal strings
  # Always reference them via var.*, data sources, or AWS Secrets Manager
  access_key      = var.aws_access_key
  secret_key      = var.aws_secret_key

  # Use least-privilege IAM policies
  # Never use '*' in actions or resources unless the task strictly requires it, and prefer specific ARNs
  # Set minimum required permissions for all IAM roles and instance profiles
  # Restrict network exposure
  # Set explicit CIDR blocks in security group ingress rules
  # Avoid 0.0.0.0/0 unless explicitly required by the task
  # Enforce encryption in transit
  # Use HTTPS/TLS endpoints and avoid plain HTTP
  # Use strong encryption algorithms
  # Add integrity checks for any downloaded resources or provisioner scripts
  # Do not leave TODO, FIXME, or placeholder security comments in the code
  # Either implement the security control or omit the comment
}