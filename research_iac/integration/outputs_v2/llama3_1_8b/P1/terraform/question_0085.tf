# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Data source for AWS Secrets Manager
data "aws_secretsmanager_secret" "route53_api_key" {
  name = "route53-api-key"
}

data "aws_secretsmanager_secret_version" "route53_api_key_value" {
  secret_id = data.aws_secretsmanager_secret.route53_api_key.id
}

# Data source for AWS Secrets Manager (API key)
data "aws_secretsmanager_secret" "route53_api_secret" {
  name = "route53-api-secret"
}

data "aws_secretsmanager_secret_version" "route53_api_secret_value" {
  secret_id = data.aws_secretsmanager_secret.route53_api_secret.id
}

# IAM role for Route 53 routing policy
resource "aws_iam_role" "route53_routing_policy" {
  name        = "route53-routing-policy"
  description = "Route 53 routing policy IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Route 53 routing policy
resource "aws_iam_policy" "route53_routing_policy" {
  name        = "route53-routing-policy"
  description = "Route 53 routing policy IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "route53:GetResourceRecordSets",
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "route53:CreateService",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

# IAM role policy attachment
resource "aws_iam_role_policy_attachment" "route53_routing_policy_attach" {
  role       = aws_iam_role.route53_routing_policy.name
  policy_arn = aws_iam_policy.route53_routing_policy.arn
}

# Route 53 zone
resource "aws_route53_zone" "primary" {
  name              = "example.com"
  delegation_set_id = aws_route53_delegation_set.primary.id

  vpc {
    vpc_id = var.vpc_id
  }
}

# Route 53 routing policy
resource "aws_route53_routing_policy" "location_based" {
  name            = "location-based-routing-policy"
  route_53_zone   = aws_route53_zone.primary.name
  location        = "US"
  routing_region = var.aws_region

  depends_on = [aws_route53_delegation_set.primary]
}

resource "aws_route53_routing_policy" "location_based_eu" {
  name            = "location-based-routing-policy-eu"
  route_53_zone   = aws_route53_zone.primary.name
  location        = "EU"
  routing_region = var.aws_region

  depends_on = [aws_route53_delegation_set.primary]
}

# Route 53 record set group
resource "aws_route53_record_set_group" "primary_us" {
  name            = aws_route53_routing_policy.location_based.name
  route_53_zone   = aws_route53_zone.primary.name
  location        = "US"
  routing_region = var.aws_region

  depends_on = [aws_route53_delegation_set.primary]
}

resource "aws_route53_record_set_group" "primary_eu" {
  name            = aws_route53_routing_policy.location_based_eu.name
  route_53_zone   = aws_route53_zone.primary.name
  location        = "EU"
  routing_region = var.aws_region

  depends_on = [aws_route53_delegation_set.primary]
}