resource "lightsail_disk" "example" {
  name_prefix = "example-disk"
  size        = 10
}

resource "lightsail_instance" "example" {
  name           = "example-instance"
  region         = "us-east-2"
  availability_zone = "us-east-2a"
  blueprint_id    = "string" # replace with actual blueprint ID
  bundle_id       = "string" # replace with actual bundle ID

  disk {
    name = lightsail_disk.example.name
  }
}