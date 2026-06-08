provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-1" {
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class       = "db.t3.micro"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-2" {
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class       = "db.t3.micro"
  skip_final_snapshot  = true
}

resource "aws_route53_record" "weighted_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.example.com"
  type    = "A"

  set_identifier = "replica-1"
  weighted_routing_policy {
    weight = 50
  }
  alias {
    name                   = aws_db_instance.replica-1.address
    zone_id                = data.aws_route53_zone.selected.zone_id
    evaluate_target_health = true
  }

  set_identifier = "replica-2"
  weighted_routing_policy {
    weight = 50
  }
  alias {
    name                   = aws_db_instance.replica-2.address
    zone_id                = data.aws_route53_zone.selected.zone_id
    evaluate_target_health = true
  }
}

data "aws_route53_zone" "selected" {
  name         = aws_route53_zone.main.name
  private_zone = false
}