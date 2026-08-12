provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  name                = "example-cluster"
  number_of_broker_nodes = 3

  configuration_info {
    arn      = aws_msk_configuration.example.arn
    revision = aws_msk_configuration.example.revision
  }

  encryption_in_ transit {
    client_velocity_tls_security_level = "TLS_1_2"
  }

  open_monitoring {
    jmx_prometheus_exporter {
      enabled_in_cluster    = true
      jmx_promethues_url = "http://some-jmx-prom-url.com:9304/metrics"
    }
  }
}