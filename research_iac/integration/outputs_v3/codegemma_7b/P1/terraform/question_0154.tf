provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "my-lambda-layer"
  description = "My Lambda layer"
  compatible_runtimes = ["python3.8"]

  content {
    zip_file = "lambda_layer_payload.zip"
  }
}