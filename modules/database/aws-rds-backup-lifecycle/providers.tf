terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # No version pin here — the consuming root pins the AWS provider.
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}
