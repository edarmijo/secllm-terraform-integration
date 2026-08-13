resource "aws_kendra_data_source" "example" {
  name           = "example-data-source"
  index_id       = aws_kendra_index.example.id
  type           = "S3_ Bucket"
  url            = "https://example.com/my-bucket/"
  url_exclusion_patterns = [
    "exclude-this-directory/*",
    "exclude-this-file.txt",
  ]
  url_inclusion_patterns = [
    "include-this-directory/*",
    "include-this-file.txt",
  ]
}