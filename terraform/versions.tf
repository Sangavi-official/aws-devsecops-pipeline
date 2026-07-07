# Terraform + provider versions, and where the "state" file lives.
# State = Terraform's memory of what it has already created in AWS.
# We keep it in a private S3 bucket so the GitHub Actions pipeline can
# remember state between runs. use_lockfile prevents two runs from
# writing at the same time (S3-native locking, Terraform >= 1.10).

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }

  backend "s3" {
    bucket       = "tfstate-634670495126"
    key          = "devsecops/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
