resource "aws_lambda_layer_version" "example" {
  layer_name = "example-layer"
  filename   = "lambda_layer_payload.zip"

  source_code_hash = filebase64sha256("lambda_layer_payload.zip")

  compatible_runtimes = ["python3.8"]

  # Add any additional configuration options as needed
}