resource "aws_glacier_vault" "example" {
  name = "example-vault"
}

resource "aws_iam_policy" "example" {
  name        = "example-policy"
  description = "Policy for accessing the S3 Glacier vault"

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "glacier:ListVaults",
      "Resource": "${aws_glacier_vault.example.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "glacier:GetVaultAccessPolicy",
      "Resource": "${aws_glacier_vault.example.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "glacier:SetVaultAccessPolicy",
      "Resource": "${aws_glacier_vault.example.arn}"
    }
  ]
}
EOF
}