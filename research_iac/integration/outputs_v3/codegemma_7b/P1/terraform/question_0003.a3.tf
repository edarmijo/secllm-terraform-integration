resource "aws_route53_record_set" "weighted_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name = aws_db_instance.primary.endpoint
    weight = 40
  }

  alias {
    name = aws_db_instance.replica_us_east.endpoint
    weight = 20
  }

  alias {
    name = aws_db_instance.replica_eu_central.endpoint
    weight = 20
  }

  alias {
    name = aws_db_instance.replica_ap_southeast.endpoint
    weight = 20
  }
}