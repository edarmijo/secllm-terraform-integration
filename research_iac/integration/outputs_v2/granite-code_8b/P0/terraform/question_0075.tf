resource "aws_kendra_data_source" "example" {
  name           = "example-data-source"
  index_id       = aws_kendra_index.example.id
  type           = "S3_ Bucket"
  url            = "s3://my-bucket/my-folder/"
  url_exclusion_patterns = [
    "exclude-this-file.pdf",
    "exclude-this-folder/*",
  ]
  url_inclusion_patterns = [
    "include-this-file.txt",
    "include-this-folder/*",
  ]
}