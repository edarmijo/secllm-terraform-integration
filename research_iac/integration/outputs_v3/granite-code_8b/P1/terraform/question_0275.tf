resource "aws_s3_bucket" "example" {
  bucket = "mybucket"

  metrics {
    # Add your desired metrics configuration here
  }
}