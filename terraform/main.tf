provider "aws" {
  region = var.aws_region

  # Every resource gets these tags automatically - useful for cost
  # tracking and for proving which IaC repo owns a resource.
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Repo      = "Sangavi-official/aws-devsecops-pipeline"
    }
  }
}
