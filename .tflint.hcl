config {
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Modules intentionally omit provider version pins: the consuming root owns the
# version via its own required_providers / default_tags provider. This is the
# library's default-provider pattern, so the "recommended" preset's version-pin
# rule is disabled here on purpose.
rule "terraform_required_providers" {
  enabled = false
}

# Several AWS-ruleset route53 format rules panic ("attribute from null value")
# on count-gated resources whose object input variable defaults to null and is
# thus null at lint time (e.g. aws-route53's var.zone). The code is valid and
# precondition-guarded, so these crashing rules are disabled.
rule "aws_route53_record_invalid_name" {
  enabled = false
}

rule "aws_route53_zone_invalid_comment" {
  enabled = false
}

rule "aws_route53_zone_invalid_name" {
  enabled = false
}

plugin "aws" {
  enabled = true
  version = "0.37.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
