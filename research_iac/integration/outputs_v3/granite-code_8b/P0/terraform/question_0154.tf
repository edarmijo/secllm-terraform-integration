resource "aws_lambda_layer_version" "example" {
  layer_name = "example"
  filename   = "lambda_layer_payload.zip"
}