# aws-cognito

Provisions an Amazon Cognito user pool with an optional hosted-UI domain, OAuth
resource servers, and app clients, following the ECV module standard.

## Usage

```hcl
module "cognito" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/security/aws-cognito?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name  = "sample-app"
  environment   = "dev"
  domain_prefix = "sample-app-dev"

  resource_servers = {
    api = {
      identifier = "https://api.sample-app.example.com"
      name       = "sample-app-api"
      scopes = [
        { scope_name = "read", scope_description = "Read access" },
        { scope_name = "write", scope_description = "Write access" },
      ]
    }
  }

  app_clients = {
    backend = {
      generate_secret      = true
      allowed_oauth_flows  = ["client_credentials"]
      allowed_oauth_scopes = ["https://api.sample-app.example.com/read"]
    }
  }

  tags = { CostCenter = "payments" }
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
standard account tags come from the root's provider `default_tags`; the module
only adds a `Name` tag and whatever you pass in `tags`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `allow_admin_create_user_only` | bool | `true` | Disable self sign-up. |
| `domain_prefix` | string | `null` | Hosted-UI domain prefix (globally unique). |
| `resource_servers` | map(object) | `{}` | OAuth resource servers and scopes. |
| `app_clients` | map(object) | `{}` | App clients and their OAuth config. |
| `tags` | map(string) | `{}` | Extra tags merged onto every resource. |

See [`variables.tf`](./variables.tf) for the full object shapes.

## Outputs

| Name | Description |
|------|-------------|
| `user_pool_id` | User pool ID. |
| `user_pool_arn` | User pool ARN. |
| `user_pool_endpoint` | User pool endpoint. |
| `domain` | Hosted-UI domain URL (null when no domain). |
| `client_ids` | Map of app-client key to client ID. |
| `client_secrets` | Map of app-client key to client secret (sensitive). |
