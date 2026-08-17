setting {
  namespace = "aws:ec2:vpc"
  name      = "ELBSubnets"
  value     = jsonencode([aws_subnet.myenv_us_east.id])
}