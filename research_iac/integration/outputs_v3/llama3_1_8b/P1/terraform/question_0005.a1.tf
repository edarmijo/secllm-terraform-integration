variable "aws_region" {
  type        = string
}

variable "db_username" {
  type        = string
}

variable "db_password" {
  type        = string
}

variable "primary_db_instance_dns_name" {
  type        = string
}

variable "primary_db_instance_hosted_zone_id" {
  type        = string
}

variable "replica_1_db_instance_dns_name" {
  type        = string
}

variable "replica_1_db_instance_hosted_zone_id" {
  type        = string
}

variable "replica_2_db_instance_dns_name" {
  type        = string
}

variable "replica_2_db_instance_hosted_zone_id" {
  type        = string
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "db_instance_credentials" {
  name        = "main-db-instance-credentials"
  description = "Credentials for main db instance and its replicas"
}

resource "aws_secretsmanager_secret_version" "db_instance_credentials" {
  secret_id     = aws_secretsmanager_secret.db_instance_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

data "aws_region" "current" {}

resource "aws_route53_zone" "main" {
  name        = "main.com"
  comment     = "Main zone for main domain"
}

resource "aws_route53_record" "primary_db_instance" {
  zone_id = aws_route53_zone.main.id
  name    = "primary.main.com"
  type    = "CNAME"
  alias {
    name                   = var.primary_db_instance_dns_name
    zone_id                = var.primary_db_instance_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_1_db_instance" {
  zone_id = aws_route53_zone.main.id
  name    = "replica-1.main.com"
  type    = "CNAME"
  alias {
    name                   = var.replica_1_db_instance_dns_name
    zone_id                = var.replica_1_db_instance_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_2_db_instance" {
  zone_id = aws_route53_zone.main.id
  name    = "replica-2.main.com"
  type    = "CNAME"
  alias {
    name                   = var.replica_2_db_instance_dns_name
    zone_id                = var.replica_2_db_instance_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "primary_db_instance" {
  alarm_identifier = "PrimaryDBInstanceHealthCheck"
  health_check_config {
    enabled        = true
    resource_path  = "/"
    port            = 80
    type            = "HTTP"
    request_interval = 30
    failure_threshold = 3
  }
}

resource "aws_route53_health_check" "replica_1_db_instance" {
  alarm_identifier = "Replica1DBInstanceHealthCheck"
  health_check_config {
    enabled        = true
    resource_path  = "/"
    port            = 80
    type            = "HTTP"
    request_interval = 30
    failure_threshold = 3
  }
}

resource "aws_route53_health_check" "replica_2_db_instance" {
  alarm_identifier = "Replica2DBInstanceHealthCheck"
  health_check_config {
    enabled        = true
    resource_path  = "/"
    port            = 80
    type            = "HTTP"
    request_interval = 30
    failure_threshold = 3
  }
}

resource "aws_route53_traffic_policy" "main" {
  name           = "MainTrafficPolicy"
  description    = "Traffic policy for main domain"
  comment        = "This traffic policy splits users between primary and replica db instances"

  query_log_config {
    enabled = true
  }

  record_set {
    name      = "main.com."
    type      = "SOA"
    ttl       = 300
    port      = 53
    priority  = 10

    value = aws_route53_zone.main.name_servers.0
  }
}

resource "aws_route53_traffic_policy_instance" "primary_db_instance" {
  traffic_policy_id = aws_route53_traffic_policy.main.id
  name              = "PrimaryDBInstance"
  description       = "Traffic policy instance for primary db instance"

  record_set {
    name      = "main.com."
    type      = "A"
    ttl       = 300
    port      = 80

    value = aws_route53_record.primary_db_instance.name
  }
}

resource "aws_route53_traffic_policy_instance" "replica_1_db_instance" {
  traffic_policy_id = aws_route53_traffic_policy.main.id
  name              = "Replica1DBInstance"
  description       = "Traffic policy instance for replica 1 db instance"

  record_set {
    name      = "main.com."
    type      = "A"
    ttl       = 300
    port      = 80

    value = aws_route53_record.replica_1_db_instance.name
  }
}

resource "aws_route53_traffic_policy_instance" "replica_2_db_instance" {
  traffic_policy_id = aws_route53_traffic_policy.main.id
  name              = "Replica2DBInstance"
  description       = "Traffic policy instance for replica 2 db instance"

  record_set {
    name      = "main.com."
    type      = "A"
    ttl       = 300
    port      = 80

    value = aws_route53_record.replica_2_db_instance.name
  }
}

resource "aws_route53_traffic_policy_rule" "primary_replica_split" {
  traffic_policy_id = aws_route53_traffic_policy.main.id
  name              = "PrimaryReplicaSplit"
  description       = "Traffic policy rule for splitting users between primary and replica db instances"

  record_set {
    name      = "main.com."
    type      = "A"
    ttl       = 300
    port      = 80

    value = aws_route53_record.primary_db_instance.name
  }

  weighted_routing_policy {
    weight = 50
  }
}

resource "aws_route53_traffic_policy_rule" "replica_1_replica_2_split" {
  traffic_policy_id = aws_route53_traffic_policy.main.id
  name              = "Replica1Replica2Split"
  description       = "Traffic policy rule for splitting users between replica 1 and replica 2 db instances"

  record_set {
    name      = "main.com."
    type      = "A"
    ttl       = 300
    port      = 80

    value = aws_route53_record.replica_1_db_instance.name
  }

  weighted_routing_policy {
    weight = 50
  }
}