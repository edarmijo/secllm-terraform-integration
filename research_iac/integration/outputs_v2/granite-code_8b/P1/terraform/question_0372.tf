resource "lightsail_disk" "example" {
  name_tag = "example-disk"
  size     = 10
  region   = "us-east-2"

  tags = {
    Name = "example-disk"
  }
}

resource "lightsail_instance" "example" {
  name_tag = "example-instance"
  region   = "us-east-2"
  blueprint_id = "string" # replace with actual blueprint ID
  bundle_id    = "string" # replace with actual bundle ID

  disks = [
    {
      disk_name = lightsail_disk.example.name_tag
    }
  ]

  tags = {
    Name = "example-instance"
  }
}