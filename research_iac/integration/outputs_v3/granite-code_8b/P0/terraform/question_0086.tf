resource "aws_route53_traffic_policy" "example" {
  name = "example-traffic-policy"

  traffic_policy_document = <<EOF
{
  "Statement": [
    {
      "Action": "allow",
      "Effect": "allow",
      "Resource": [
        "arn:aws:s3:::examplebucket/*",
        "arn:aws:s3:::examplebucket"
      ],
      "Principal": "*"
    }
  ],
  "Version": "2012-10-17"
}
EOF

}