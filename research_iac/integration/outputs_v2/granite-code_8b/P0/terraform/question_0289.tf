resource "aws_s3_bucket" "example" {
  bucket = "tf-acc-test-s3-owner-pays"

  payment_policy = <<EOF
{
    "PaymentRequest": {
        "Payer": "BucketOwner"
    }
}
EOF
}