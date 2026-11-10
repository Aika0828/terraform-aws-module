locals {
  name       = "${var.project_name}-${var.environment}"
  stage_name = var.stage_name != null ? var.stage_name : var.environment

  # Key routes by route_key for stable for_each addressing.
  routes = { for r in var.routes : r.route_key => r }
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.name
  protocol_type = var.protocol_type

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_origins     = cors_configuration.value.allow_origins
      allow_methods     = cors_configuration.value.allow_methods
      allow_headers     = cors_configuration.value.allow_headers
      expose_headers    = cors_configuration.value.expose_headers
      allow_credentials = cors_configuration.value.allow_credentials
      max_age           = cors_configuration.value.max_age
    }
  }

  tags = merge(var.tags, { Name = local.name })
}

resource "aws_apigatewayv2_stage" "this" {
  #checkov:skip=CKV_AWS_76:API Gateway access logging requires a consumer-provided log destination
  api_id      = aws_apigatewayv2_api.this.id
  name        = local.stage_name
  auto_deploy = true

  tags = merge(var.tags, { Name = "${local.name}-${local.stage_name}" })
}

# Optional Lambda authorizer. The authorizer Lambda and any permission to
# invoke it are owned by the caller — this module takes only its invoke ARN.
resource "aws_apigatewayv2_authorizer" "this" {
  count = var.authorizer != null ? 1 : 0

  api_id                            = aws_apigatewayv2_api.this.id
  name                              = var.authorizer.name
  authorizer_type                   = var.authorizer.authorizer_type
  authorizer_uri                    = var.authorizer.authorizer_uri
  identity_sources                  = var.authorizer.identity_sources
  authorizer_payload_format_version = var.authorizer.authorizer_payload_format_version
  authorizer_result_ttl_in_seconds  = var.authorizer.authorizer_result_ttl_in_seconds
  enable_simple_responses           = var.authorizer.enable_simple_responses
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = local.routes

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = each.value.integration_type
  integration_uri        = each.value.integration_uri
  integration_method     = each.value.integration_method
  connection_type        = each.value.connection_type
  payload_format_version = each.value.payload_format_version
  description            = "Integration for ${each.value.route_key}"
}

resource "aws_apigatewayv2_route" "this" {
  #checkov:skip=CKV_AWS_309:Route authorization type is defined by the consumer per route
  for_each = local.routes

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.value.route_key
  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorization_type == "CUSTOM" ? one(aws_apigatewayv2_authorizer.this[*].id) : null
  target             = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"
}
