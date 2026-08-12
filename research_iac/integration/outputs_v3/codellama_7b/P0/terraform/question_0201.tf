provider "google" {
  region = "us-east1"
}

resource "google_msk_cluster" "example" {
  name     = "example-cluster"
  location = "us-east1"

  broker_count = 3

  config {
    kafka_config {
      default_replication_factor = 3
    }
  }
}