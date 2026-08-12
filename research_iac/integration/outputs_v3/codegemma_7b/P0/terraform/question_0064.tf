provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "my-firehose-stream"

  destination_id = aws_opensearchservice_domain.opensearch_domain.id

  source_kinesis_stream {
    arn = aws_kinesis_stream.my_kinesis_stream.arn
  }
}

resource "aws_opensearchservice_domain" "opensearch_domain" {
  domain_name = "my-opensearch-domain"

  cluster_config {
    instance_count = 1
    instance_type = "t3.medium.elasticsearch"
  }

  elasticsearch_version = "7.10"

  access_policies {
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "es:DescribeElasticsearchDomain",
        "es:ListDomainNames",
        "es:ESHttp"
      ],
      "Resource": [
        "arn:aws:es:us-east-1:123456789012:domain/my-opensearch-domain/*"
      ]
    }
  ]
}
POLICY
  }
}

resource "aws_kinesis_stream" "my_kinesis_stream" {
  name = "my-kinesis-stream"
}