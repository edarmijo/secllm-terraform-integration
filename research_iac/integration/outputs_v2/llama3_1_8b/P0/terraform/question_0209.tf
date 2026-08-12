provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "msk_service_linked_role" {
  name        = "MSKServiceLinkedRole-${aws_caller_identity.account_id}"
  description = "Service-linked role for MSK"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.${aws_region}.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_service_linked_role_attach" {
  role       = aws_iam_role.msk_service_linked_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonMSKServiceRole"
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "msk-cluster-example"
  kafka_version          = "2.6.1"
  number_of_node_groups = 1
  node_group_scaling_config {
    instance_type = "kafka.m5.large"
    region_info {
      region = aws_region
    }
  }

  broker_node_properties {
    instance_type = "kafka.m5.large"
  }

  ebs_volume_config {
    volume_size = 32
  }

  vpc_settings {
    subnet_ids = [aws_subnet.example.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.msk_service_linked_role_attach,
  ]
}

resource "aws_security_group" "example" {
  name        = "msk-sg-example"
  description = "Security group for MSK cluster"

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = aws_region
}