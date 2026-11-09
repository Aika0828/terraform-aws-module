terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # No version pin here — the consuming root pins the AWS provider.
    }
    # archive is required to build a deployment package from a source directory
    # or file; the consuming root pins its version.
    archive = {
      source = "hashicorp/archive"
    }
  }
}
