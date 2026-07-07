# Zips the lambda/ folder and deploys it as a function.
# Lambda Always-Free tier: 1M requests + 400,000 GB-seconds per month.

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/builds/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  # checkov:skip=CKV_AWS_158:Encrypted by default with AWS-managed keys. A customer-managed KMS key costs $1/month, out of scope for an Always-Free project.
  name              = "/aws/lambda/visitor-counter"
  retention_in_days = 365
}

resource "aws_lambda_function" "counter" {
  # checkov:skip=CKV_AWS_50:X-Ray tracing intentionally off - single-function demo, keeps moving parts minimal.
  # checkov:skip=CKV_AWS_115:New AWS accounts have a low account-level concurrency cap; setting reserved concurrency would fail the deploy. Documented in README.
  # checkov:skip=CKV_AWS_116:No dead-letter queue - the function is synchronous (API Gateway), so failures return HTTP errors to the caller instead of being queued.
  # checkov:skip=CKV_AWS_117:Deliberately not in a VPC - it touches no VPC resources, and VPC egress would require a NAT Gateway (~$32/month).
  # checkov:skip=CKV_AWS_173:Env var holds only a public table name (no secret). Encrypted at rest by default; a customer KMS key costs $1/month.
  # checkov:skip=CKV_AWS_272:Code signing skipped - source integrity is enforced upstream by the scanned Git repo and SHA-pinned pipeline.
  function_name    = var.project
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visits.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}
