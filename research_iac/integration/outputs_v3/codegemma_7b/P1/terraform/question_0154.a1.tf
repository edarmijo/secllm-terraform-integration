resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "my-lambda-layer"
  description = "My Lambda layer"
  compatible_runtimes = ["python3.8"]

  filename = "lambda_layer_payload.zip"
}