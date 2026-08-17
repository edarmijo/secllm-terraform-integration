resource "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
  version = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    private_subnet_ids = var.private_subnet_ids
    public_subnet_ids = var.public_subnet_ids
  }
}