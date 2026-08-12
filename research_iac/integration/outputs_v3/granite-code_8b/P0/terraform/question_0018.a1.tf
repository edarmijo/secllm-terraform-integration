resource "aws_route_table_association" "webserver_public_subnet_association" {
  subnet_id      = aws_subnet.webserver_public_subnet.id
  route_table_id = aws_route_table.webserver_public_rt.id

  tags = {
    Name = "webserver_public_subnet_association"
  }
}