locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_cognito_user_pool" "this" {
  name = local.name

  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only
  }

  tags = merge(var.tags, { Name = local.name })
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.domain_prefix != null ? 1 : 0

  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_resource_server" "this" {
  for_each = var.resource_servers

  identifier   = each.value.identifier
  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "scope" {
    for_each = each.value.scopes
    content {
      scope_name        = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = var.user_pool_clients

  name         = "${local.name}-${each.key}"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = each.value.generate_secret
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  supported_identity_providers         = each.value.supported_identity_providers
  explicit_auth_flows                  = each.value.explicit_auth_flows

  depends_on = [aws_cognito_resource_server.this]
}
