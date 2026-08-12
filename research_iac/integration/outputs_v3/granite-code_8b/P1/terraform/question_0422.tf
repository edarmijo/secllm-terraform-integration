resource "aws_efs" "example" {
  name = "example"

  lifecycle_policy {
    transition_to_ia = "AFTER_14_DAYS"
  }
}