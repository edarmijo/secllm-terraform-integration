resource "aws_efs" "example" {
  count = var.create ? 1 : 0

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  tags = {
    Name = "example-efs"
  }
}