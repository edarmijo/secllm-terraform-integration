resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name   = "lambda_layer"
  filename     = "lambda_layer_payload.zip"
  compatible_runtimes = ["python3.8"]
}