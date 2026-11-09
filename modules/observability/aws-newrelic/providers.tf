terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # No version pin here — the consuming root pins the AWS provider.
    }
    newrelic = {
      source = "newrelic/newrelic"
      # No inline provider block — the consuming root configures the
      # newrelic provider (account_id, api_key, region).
    }
  }
}
