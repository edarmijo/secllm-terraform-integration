resource "aws_lambda_layer_version" "example" {
  layer_name   = "example-layer"
  description  = "Example Lambda Layer"
  license_info = "MIT"
  compatible_runtimes = ["python3.8"]
  content {
    filename = "lambda_layer_payload.zip"
    source_code_hash = filebase64sha256("lambda_layer_payload.zip")
  }
}