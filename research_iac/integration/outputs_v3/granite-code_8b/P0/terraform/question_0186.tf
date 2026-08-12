data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-linux-2-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t2.micro"

  # ... other settings ...

  cpu_core_count     = 2
  cpu_threads_per_core = 2
}