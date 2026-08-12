provider "aws" {
  region = "us-west-2"
}

resource "aws_elasticache_cluster" "db_cache" {
  cluster_id       = "my-cluster"
  engine           = "memcached"
  node_type        = "cache.t3.micro"
  num_cache_nodes  = 1
  parameter_group_name = "default.memcached1.4"
}

resource "aws_lambda_function" "cache_handler" {
  filename      = "lambda_function_payload.zip"
  function_name = "cache-handler"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      CACHE_HOST = aws_elasticache_cluster.db_cache.cache_node_address
    }
  }
}

resource "aws_api_gateway_rest_api" "cache_api" {
  name        = "Cache API"
  description = "API for caching database calls"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "cache_resource" {
  rest_api_id = aws_api_gateway_rest_api.cache_api.id
  parent_id   = aws_api_gateway_rest_api.cache_api.root_resource_id
  path_part   = "cache"
}

resource "aws_api_gateway_method" "cache_get" {
  rest_api_id = aws_api_gateway_rest_api.cache_api.id
  resource_id = aws_api_gateway_resource.cache_resource.id
  http_method = "GET"

  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cache_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.cache_api.id
  resource_id = aws_api_gateway_resource.cache_resource.id
  http_method = aws_api_gateway_method.cache_get.http_method

  integration_http_method = "POST"
  type                    = "LAMBDA"

  uri = "arn:aws:apigateway:${aws_api_gateway_rest_api.cache_api.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cache_handler.arn}/invocations"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "cache-handler-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name   = "cache-handler-exec-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Resource = "${aws_cloudwatch_log_group.cache_logs.arn}:*"
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "cache_logs" {
  name              = "/aws/lambda/cache-handler"
  retention_in_days = 14
}