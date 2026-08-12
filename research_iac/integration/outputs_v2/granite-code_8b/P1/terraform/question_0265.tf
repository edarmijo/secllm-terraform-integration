resource "aws_iam_user" "example" {
  name = "example-user"
  path = "/"

  tags = {
    Name        = "Example User"
    Environment = "Production"
  }
}

resource "aws_iam_access_key" "example" {
  user = aws_iam_user.example.name
}