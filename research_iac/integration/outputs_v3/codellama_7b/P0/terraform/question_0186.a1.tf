provider "aws" {
  region = "us-east-1"
}

resource "aws_ami" "example" {
  name                = "example"
  description        = "Example AMI"
  architecture        = "x86_64"
  virtualization_type = "hvm"
  cpu_core_count      = 2
  cpu_threads_per_core = 2
}