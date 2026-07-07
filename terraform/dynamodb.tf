# DynamoDB table that stores the visit counter.
# PROVISIONED 1 read / 1 write stays inside the Always-Free
# 25 RCU / 25 WCU allowance, so this is $0 forever.

resource "aws_dynamodb_table" "visits" {
  # checkov:skip=CKV_AWS_119:Encrypted at rest by default with an AWS-owned key. A customer-managed KMS key costs $1/month, out of scope for an Always-Free project.
  # checkov:skip=CKV2_AWS_16:Auto Scaling intentionally disabled - fixed 1 RCU/1 WCU keeps the table inside the Always-Free 25-unit allowance.
  name           = var.project
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Continuous backups (restore to any second in the last 35 days).
  # Billed per GB of data - our table holds one tiny item, so $0.00.
  point_in_time_recovery {
    enabled = true
  }
}
