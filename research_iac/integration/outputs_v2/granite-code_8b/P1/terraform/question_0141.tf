resource "aws_redshift_cluster" "example" {
  cluster_identifier           = "example-cluster"
  node_type                    = "ds2.large"
  master_username              = "masteruser"
  master_password              = "MySuperSecretPassword"
  skip_final_snapshot          = true
  automated_snapshots_enabled  = false

  # Set the number of nodes in the cluster
  num_nodes = 2

  # Specify the version of the Amazon Redshift engine
  engine = "redshift"

  # Specify the version of the database software
  engine_version = "1.0"

  # Enable logging for the cluster
  enable_logging = true

  # Set the storage type for the cluster
  storage_type = "gp2"

  # Allocate 4GB of memory to each node in the cluster
  cluster_memory = 4

  # Allocate 2 vCPU cores to each node in the cluster
  cluster_cpu = 2

  # Specify the availability zone where the cluster will be created
  availability_zone = "us-east-1a"

  # Set the port number for the cluster
  port = 5439

  # Enable encryption at rest for the cluster
  encrypted = true

  # Set the subnet group to use for the cluster
  subnet_group = aws_redshift_subnet_group.example.id
}

resource "aws_redshift_endpoint_authorization" "example" {
  account                      = "012345678910"
  authorization_proof          = filebase64("path/to/authorization_proof")
  cluster_identifier           = aws_redshift_cluster.example.id
}