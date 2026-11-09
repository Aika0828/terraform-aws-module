locals {
  name    = "${var.project_name}-${var.environment}"
  comment = var.comment != null ? var.comment : "${local.name} CloudFront distribution"
}

# Optional VPC origin (e.g. fronting an internal ALB).
resource "aws_cloudfront_vpc_origin" "this" {
  count = var.vpc_origin != null ? 1 : 0

  vpc_origin_endpoint_config {
    name                   = "${local.name}-vpc-origin"
    arn                    = var.vpc_origin.arn
    http_port              = var.vpc_origin.http_port
    https_port             = var.vpc_origin.https_port
    origin_protocol_policy = var.vpc_origin.origin_protocol_policy

    origin_ssl_protocols {
      items    = var.vpc_origin.origin_ssl_protocols
      quantity = length(var.vpc_origin.origin_ssl_protocols)
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-vpc-origin" })
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = local.comment
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = var.default_root_object
  web_acl_id          = var.web_acl_id

  # VPC origin (created above).
  dynamic "origin" {
    for_each = var.vpc_origin != null ? [var.vpc_origin] : []
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = null

      vpc_origin_config {
        vpc_origin_id = aws_cloudfront_vpc_origin.this[0].id
      }
    }
  }

  # Additional origins (S3 / custom HTTP).
  dynamic "origin" {
    for_each = { for o in var.origins : o.origin_id => o }
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = origin.value.origin_path
      origin_access_control_id = origin.value.origin_access_control_id

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port              = custom_origin_config.value.http_port
          https_port             = custom_origin_config.value.https_port
          origin_protocol_policy = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols   = custom_origin_config.value.origin_ssl_protocols
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id           = var.default_cache_behavior.target_origin_id
    allowed_methods            = var.default_cache_behavior.allowed_methods
    cached_methods             = var.default_cache_behavior.cached_methods
    viewer_protocol_policy     = var.default_cache_behavior.viewer_protocol_policy
    compress                   = var.default_cache_behavior.compress
    cache_policy_id            = var.default_cache_behavior.cache_policy_id
    origin_request_policy_id   = var.default_cache_behavior.origin_request_policy_id
    response_headers_policy_id = var.default_cache_behavior.response_headers_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = var.certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != null ? var.minimum_protocol_version : null
  }

  tags = merge(var.tags, { Name = "${local.name}-cloudfront" })
}
