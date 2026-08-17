resource "aws_dax_subnet_group" "example" {
  name       = "example-dax-subnet-group"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
}