provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "static_website" {
  bucket = "my-static-website"
  acl    = "public-read"

  resource "aws_s3_object" "index_file" {
    bucket = aws_s3_bucket.static_website.bucket
    key    = "index.html"
    source = "index.html"
  }
}

resource "aws_s3_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website.bucket

  index_document {
    suffix = "index.html"
  }
}