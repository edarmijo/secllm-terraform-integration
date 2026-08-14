provider "google" {
  region = "us-east2"
}

resource "google_msk_cluster" "example" {
  name     = "example-msk-cluster"
  num_brokers = 3
  broker_version = "2.8.0"
  zookeeper_connect_string = "zookeeper1:2181,zookeeper2:2181,zookeeper3:2181"
}