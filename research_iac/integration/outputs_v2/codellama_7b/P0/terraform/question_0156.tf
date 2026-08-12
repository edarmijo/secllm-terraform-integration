resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime       = "python3.8"
  handler       = "index.handler"
  role          = aws_iam_role.test_lambda_role.arn
}

resource "aws_iam_role" "test_lambda_role" {
  name               = "test_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_ec2_image" "test_image" {
  name = "test_image"
}

resource "aws_lambda_permission" "allow_ec2_image_creation" {
  statement_id  = "AllowExecutionFromEC2ImageCreation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "ec2_image_creation" {
  name        = "EC2ImageCreationRule"
  description = "Capture EC2 image creation events"
  event_pattern = <<EOF
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["running"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "test_lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_image_creation.name
  target_id = "EC2ImageCreationTarget"
  arn       = aws_lambda_function.test_lambda.arn
}