resource "aws_codebuild_project" "example" {
  name        = "example-project"
  description = "Example CodeBuild Project"

  service_role = aws_iam_role.example.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  secondary_sources {
    type      = "GITHUB"
    location  = "https://github.com/example-org/example-repo"
    git_clone_depth = 1
  }
}

resource "aws_iam_role" "example" {
  name               = "example-codebuild-role"
  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")
}