resource "aws_codebuild_project" "example" {
  name = "example-project"

  role = aws_iam_role.example.arn

  source {
    type = "GITHUB"
    location = "github.com/example-user/example-repo.git"
  }

  secondary_source {
    type = "CODECOMMIT"
    location = "codecommit://example-repo"
  }
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy {
    name = "AmazonCodeBuildReadOnlyAccess"
  }
}