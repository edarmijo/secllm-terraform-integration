provider "aws" {
  region = var.aws_region
}

resource "aws_subnet_group" "dax_subnet_group" {
  name = "dax-subnet-group"

  subnet_ids = var.subnet_ids
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "subnet_ids" {
  type = list(string)
  default = ["subnet-12345678", "subnet-98765432"]
}