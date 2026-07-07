# HTTP API (API Gateway v2) - the public front door that invokes Lambda.

resource "aws_cloudwatch_log_group" "api" {
  # checkov:skip=CKV_AWS_158:Encrypted by default with AWS-managed keys. A customer-managed KMS key costs $1/month, out of scope for an Always-Free project.
  name              = "/aws/apigateway/visitor-counter"
  retention_in_days = 365
}

resource "aws_apigatewayv2_api" "api" {
  name          = var.project
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visits" {
 # checkov:skip=CKV_AWS_309:Public demo endpoint by design - returns a visit count, no sensitive data, no state-changing operations, and the stage throttles to 5 req/s. Auth (IAM/JWT) would block the public demo purpose.
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /visits"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  # Access logging: who called the API, when, and with what result.
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  # Throttling: caps abuse so a stranger hammering the URL cannot
  # push usage anywhere near free-tier limits.
  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 5
  }
}

# Permission for API Gateway to invoke this specific Lambda only.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
