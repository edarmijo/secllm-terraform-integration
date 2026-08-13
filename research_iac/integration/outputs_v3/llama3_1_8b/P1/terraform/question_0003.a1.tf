variable "db_password" {
  type = string
}

provider "aws" {
  region = "us-west-1"
}

# Create a secret for the database password
resource "aws_secretsmanager_secret" "db_password" {
  name        = "db-password"
  description = "Database password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Create a database instance in us-west-1
resource "aws_db_instance" "primary" {
  identifier          = "main-primary"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.db_password.secret_string
  vpc_security_group_ids = [aws_security_group.main.id]
}

# Create a security group for the database instances
resource "aws_security_group" "main" {
  name        = "main-db-sg"
  description = "Database security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a weighted routing policy in Route 53
resource "aws_route53_zone" "main" {
  name        = "main.com"
  comment     = "Main zone"
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "main-primary.main.com"
  type    = "A"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "primary" {
  name               = "main-primary-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = aws_subnet.primary.*.id

  access_logs {
    bucket        = aws_s3_bucket.lb_log_bucket.id
    enabled       = true
  }
}

resource "aws_lb_target_group" "primary" {
  name     = "main-primary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "primary" {
  load_balancer_arn = aws_lb.primary.arn
  port              = "traffic-port"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.primary.arn
    type             = "forward"
  }
}

# Create a database instance in us-east-1
resource "aws_db_instance" "replica_us_east" {
  identifier        = "main-replica-us-east"
  engine            = "mysql"
  instance_class    = "db.t2.micro"
  username          = "admin"
  password          = aws_secretsmanager_secret_version.db_password.secret_string
  vpc_security_group_ids = [aws_security_group.us_east.id]
  replication_source_identifier = aws_db_instance.primary.arn
}

resource "aws_security_group" "us_east" {
  name        = "us-east-db-sg"
  description = "Database security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_instance" "replica_eu_central" {
  identifier        = "main-replica-eu-central"
  engine            = "mysql"
  instance_class    = "db.t2.micro"
  username          = "admin"
  password          = aws_secretsmanager_secret_version.db_password.secret_string
  vpc_security_group_ids = [aws_security_group.eu_central.id]
  replication_source_identifier = aws_db_instance.primary.arn
}

resource "aws_security_group" "eu_central" {
  name        = "eu-central-db-sg"
  description = "Database security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_instance" "replica_ap_southeast" {
  identifier        = "main-replica-ap-southeast"
  engine            = "mysql"
  instance_class    = "db.t2.micro"
  username          = "admin"
  password          = aws_secretsmanager_secret_version.db_password.secret_string
  vpc_security_group_ids = [aws_security_group.ap_southeast.id]
  replication_source_identifier = aws_db_instance.primary.arn
}

resource "aws_security_group" "ap_southeast" {
  name        = "ap-southeast-db-sg"
  description = "Database security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a weighted routing policy in Route 53
resource "aws_route53_record" "replica_us_east" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "main-replica-us-east.main.com"
  type    = "A"

  alias {
    name                   = aws_lb.replica_us_east.dns_name
    zone_id                = aws_lb.replica_us_east.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_eu_central" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "main-replica-eu-central.main.com"
  type    = "A"

  alias {
    name                   = aws_lb.replica_eu_central.dns_name
    zone_id                = aws_lb.replica_eu_central.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_ap_southeast" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "main-replica-ap-southeast.main.com"
  type    = "A"

  alias {
    name                   = aws_lb.replica_ap_southeast.dns_name
    zone_id                = aws_lb.replica_ap_southeast.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_weighted_routing_policy" "main" {
  name            = "main-weighted-routing-policy"
  routing_policies = [
    {
      domain_name       = "main-primary.main.com",
      weight            = 5,
      geo_location      = null,
      id                = aws_route53_record.primary.id
    },
    {
      domain_name       = "main-replica-us-east.main.com",
      weight            = 3,
      geo_location      = null,
      id                = aws_route53_record.replica_us_east.id
    },
    {
      domain_name       = "main-replica-eu-central.main.com",
      weight            = 2,
      geo_location      = null,
      id                = aws_route53_record.replica_eu_central.id
    },
    {
      domain_name       = "main-replica-ap-southeast.main.com",
      weight            = 1,
      geo_location      = null,
      id                = aws_route53_record.replica_ap_southeast.id
    }
  ]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "primary" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Primary Subnet"
  }
}

resource "aws_s3_bucket" "lb_log_bucket" {
  bucket = "my-lb-logs-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_lb" "replica_us_east" {
  name               = "Replica US East LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.us_east.id]
  subnets            = aws_subnet.replica_us_east.*.id

  access_logs {
    bucket        = aws_s3_bucket.lb_log_bucket.id
    enabled       = true
  }
}

resource "aws_lb_target_group" "replica_us_east" {
  name     = "Replica US East TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "replica_us_east" {
  load_balancer_arn = aws_lb.replica_us_east.arn
  port              = "traffic-port"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.replica_us_east.arn
    type             = "forward"
  }
}

resource "aws_subnet" "replica_us_east" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Replica US East Subnet"
  }
}

resource "aws_lb" "replica_eu_central" {
  name               = "Replica EU Central LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eu_central.id]
  subnets            = aws_subnet.replica_eu_central.*.id

  access_logs {
    bucket        = aws_s3_bucket.lb_log_bucket.id
    enabled       = true
  }
}

resource "aws_lb_target_group" "replica_eu_central" {
  name     = "Replica EU Central TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "replica_eu_central" {
  load_balancer_arn = aws_lb.replica_eu_central.arn
  port              = "traffic-port"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.replica_eu_central.arn
    type             = "forward"
  }
}

resource "aws_subnet" "replica_eu_central" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Replica EU Central Subnet"
  }
}

resource "aws_lb" "replica_ap_southeast" {
  name               = "Replica AP Southeast LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ap_southeast.id]
  subnets            = aws_subnet.replica_ap_southeast.*.id

  access_logs {
    bucket        = aws_s3_bucket.lb_log_bucket.id
    enabled       = true
  }
}

resource "aws_lb_target_group" "replica_ap_southeast" {
  name     = "Replica AP Southeast TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "replica_ap_southeast" {
  load_balancer_arn = aws_lb.replica_ap_southeast.arn
  port              = "traffic-port"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.replica_ap_southeast.arn
    type             = "forward"
  }
}

resource "aws_subnet" "replica_ap_southeast" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "Replica AP Southeast Subnet"
  }
}