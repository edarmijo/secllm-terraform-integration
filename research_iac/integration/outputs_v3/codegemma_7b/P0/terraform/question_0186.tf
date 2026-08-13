provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0b4484a44444444444" # Latest Amazon Linux 2 AMI
  instance_type = "t2.micro"
  cpu_options {
    core_count = 2
    threads_per_core = 2
  }
}