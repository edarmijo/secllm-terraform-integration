provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-website-bucket"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }
}