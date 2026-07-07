# Project Report: Shift-Left DevSecOps Pipeline on AWS

## Abstract

Most cloud breaches start with a small configuration mistake. This project builds a pipeline where infrastructure code is security scanned before every deployment, the deployment itself uses no stored credentials, and the live AWS account is measured against the CIS AWS Foundations Benchmark. The account compliance score improved from 27.5% to 45.3%, at a total cost of zero.

## Introduction

I am a beginner. Before this project I had never used Terraform, AWS CLI or GitHub Actions. I wanted one project that shows the full security lifecycle: write infrastructure as code, scan it, deploy it safely, audit the result, fix things, and prove the improvement with evidence. This report explains what I built and what I actually typed, so anyone can repeat it.

## Tech stack

- AWS: Lambda (Python 3.12), DynamoDB, API Gateway HTTP API, IAM, S3 (Terraform state), CloudWatch Logs, AWS Budgets
- IaC: Terraform
- CI/CD: GitHub Actions
- Security tools: Checkov (IaC scanning), gitleaks (secret scanning), Prowler (CSPM / CIS benchmark)
- Identity: GitHub OIDC federation into AWS IAM roles

## Techniques used

- Shift-left security: scanners run before deploy, and a failed scan blocks the deploy job.
- Keyless deployment: GitHub OIDC gives the workflow 15 minute credentials scoped to this one repository. No AWS keys exist in GitHub secrets.
- Least privilege IAM: the deploy role can only touch this project resources. The Lambda role can do one action on one table.
- Supply chain pinning: every action is pinned to a full commit SHA because tags can be moved by attackers.
- Documented suppressions: every skipped Checkov check has an inline justification, cost or architecture.
- Evidence based compliance: raw Prowler CSV output for before and after is committed in /evidence.

## Process, step by step (what I actually did)

1. Created a zero-spend AWS Budget alert so any accidental cost emails me.
2. Created an IAM user (devsecops-admin) and stopped using the root account.
3. Installed AWS CLI and Terraform on Windows, connected the CLI with aws configure.
4. Wrote the Terraform for DynamoDB, Lambda, API Gateway and IAM, plus the Lambda Python code.
5. Wrote two GitHub Actions workflows: the scan-then-deploy pipeline and the Prowler compliance scan.
6. Created the S3 state bucket, the OIDC provider, and two IAM roles (deploy and read-only audit) using the AWS CLI.
7. Pushed to GitHub. Checkov blocked the first deploy (public API route, CKV_AWS_309). I wrote a justification and pushed again.
8. Deploy failed once more because my least privilege role was missing log delivery permissions. I added exactly the actions the error named.
9. Pipeline went green. The live URL returned JSON from Lambda and DynamoDB.
10. Ran Prowler. Baseline score 27.5% (38 of 138 CIS checks).
11. Hardened for free: 14 character password policy, account wide S3 public access block, IAM Access Analyzer in every region, EBS encryption by default in every region, admin rights moved from user to a group, support role, HTTPS only state bucket policy, MFA on root and on my IAM user.
12. Ran Prowler again: 45.3% (63 of 139). Committed both raw reports to /evidence.
13. GitHub push protection blocked my evidence commit because the raw report contained my own access key ID. I redacted it and rewrote the commit.

## Insights

- The pipeline catching my own mistakes taught me more than any tutorial.
- Reading an IAM error message carefully usually tells you the exact fix.
- Zero cost is a real constraint that forces honest trade-off decisions, and writing those decisions down is what makes them defensible.

## Results

- CIS AWS Foundations Benchmark v4.0 score: 27.5% before, 45.3% after. Evidence: /evidence folder.
- Working public API deployed only through the security gated pipeline.
- Zero AWS spend, verified by the Budgets console.

Screenshots (in docs/images):
- green-pipeline.png : all three jobs green in GitHub Actions
- blocked-deploy.png : the run where Checkov blocked the deploy
- live-api.png : the API responding in a browser
- budget-zero.png : AWS Budgets showing 0.00 spend

## How to run and verify (for a beginner)

1. Open the live URL in a browser. Refresh it. The visits number increases. That proves API Gateway, Lambda and DynamoDB are working.
2. Open the Actions tab in this repo. Green runs show the scans passed. Open any run to read the Checkov and gitleaks logs.
3. Open evidence/prowler-before and evidence/prowler-after. Open the CSV, filter the STATUS column, count PASS yourself.
4. To reproduce: fork this repo, create your own state bucket and OIDC roles using the JSON files in /setup, update the account ID, and push.

## References

- CIS AWS Foundations Benchmark: https://www.cisecurity.org/benchmark/amazon_web_services
- Checkov: https://www.checkov.io
- gitleaks: https://github.com/gitleaks/gitleaks
- Prowler: https://github.com/prowler-cloud/prowler
- GitHub OIDC to AWS: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- Terraform AWS provider: https://registry.terraform.io/providers/hashicorp/aws
