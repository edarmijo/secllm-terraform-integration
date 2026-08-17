resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "my-lambda-layer"
  description = "My Lambda Layer"
  compatible_runtimes = ["python3.8"]
  zip_file = "lambda_layer_payload.zip"
}