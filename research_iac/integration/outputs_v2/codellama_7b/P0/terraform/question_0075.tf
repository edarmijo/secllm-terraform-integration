resource "aws_kendra_data_source" "example" {
  name                   = "example-data-source"
  index_id               = aws_kendra_index.example.id
  type                   = "S3"
  s3_configuration {
    bucket_name           = "example-bucket"
    inclusion_patterns    = ["*.txt", "*.pdf"]
    exclusion_patterns    = ["*.jpg", "*.png"]
  }
}