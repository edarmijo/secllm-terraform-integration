resource "aws_sagemaker_notebook" "example" {
  name        = "example-notebook"
  role_arn    = aws_iam_role.example.arn
  instance_type = "ml.t2.medium"
  subnet_id   = aws_subnet.example.id
  security_group_ids = [aws_security_group.example.id]
}

resource "aws_iam_role" "example" {
  name        = "example-notebook-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example.id
}

resource "aws_security_group" "example" {
  name        = "example-notebook-sg"
  description = "Allow inbound traffic for example notebook"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}