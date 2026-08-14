resource "aws_lightsail_bucket_access" "example" {
  bucket_name = "my-bucket"
  access_role_name = aws_iam_role.lightsail-bucket-access.name

  resource_access {
    type = "bucket"
    bucket_name = "my-bucket"
  }
}