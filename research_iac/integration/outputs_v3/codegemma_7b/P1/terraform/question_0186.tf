provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0c4444444444444444" # Replace with the latest Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  cpu_options {
    core_count = 2
    threads_per_core = 2
  }
}