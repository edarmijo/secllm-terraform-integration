resource "aws_imeter_notebook" "example" {
  name = "example-imeter-notebook"
  role_arn = aws_iam_role.example.arn
  instance_type = "ml.t2.medium"
  volume_size_in_gb = 50
  git_repo = "https://github.com/hashicorp/terraform-provider-aws.git"
}