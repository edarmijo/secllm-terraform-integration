resource "aws_sagemaker_notebook_instance" "example" {
  name        = "example-notebook"
  role_arn    = aws_iam_role.example.arn
  instance_type = "ml.t2.medium"
  subnet_id   = aws_subnet.example.id
  security_group_ids = [aws_security_group.example.id]
}