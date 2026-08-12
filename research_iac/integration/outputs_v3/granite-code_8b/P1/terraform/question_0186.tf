resource "aws_ami" "latest_amazon_linux_2" {
  name            = "latest-amazon-linux-2"
  virtualization_type = "hvm"

  source {
    owner      = "amazon"
    name       = "amazon-linux-2-x86_64-gp2"
    most_recent = true
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "Latest Amazon Linux 2 AMI"
  }
}