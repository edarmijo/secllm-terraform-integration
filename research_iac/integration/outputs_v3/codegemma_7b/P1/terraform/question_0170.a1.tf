resource "aws_dax_subnet_group" "dax_subnet_group" {
  name = "dax-subnet-group"

  subnet_ids = var.subnet_ids
}