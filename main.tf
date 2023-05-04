terraform {
  backend "s3" {}

  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "3.2.0"
    }
    auth0 = {
      source  = "registry.terraform.io/auth0/auth0"
      version = "0.32.0"
    }
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "random" {}
provider "auth0" {}
provider "aws" {}

data "aws_region" "current" {}

resource "random_pet" "api_name" {}

resource "auth0_resource_server" "api" {
  name        = random_pet.api_name.id
  identifier  = "https://${var.dream_project_id}.${var.dream_workspace}"
  signing_alg = "RS256"

  enforce_policies = true

  allow_offline_access                            = true
  skip_consent_for_verifiable_first_party_clients = true
  dynamic "scopes" {
    for_each = var.scopes

    content {
      value       = scopes.value.value
      description = scopes.value.description
    }
  }
}

resource "random_pet" "client_name" {
  count = var.create_auth0_api_test_client ? 1 : 0
}
// test client for auth0_resource_server.api
resource "auth0_client" "client" {
  count       = var.create_auth0_api_test_client ? 1 : 0
  name        = random_pet.client_name[0].id
  description = "test client for ${auth0_resource_server.api.name}"
  app_type    = "non_interactive"
  jwt_configuration {
    alg = "RS256"
  }
  oidc_conformant = true
  grant_types     = ["client_credentials"]
}
resource "auth0_client_grant" "client_grant" {
  count     = var.create_auth0_api_test_client ? 1 : 0
  audience  = auth0_resource_server.api.identifier
  client_id = auth0_client.client[0].id
  scope     = [
  for scope in auth0_resource_server.api.scopes :
  scope.value
  ]
}

resource "aws_ssm_parameter" "test_client_secret" {
  count = var.create_auth0_api_test_client ? 1 : 0
  name        = "/auth0_api/test/${auth0_client.client.0.name}/client-secret"
  description = "The auth0 client secret"
  type        = "SecureString"
  value       = auth0_client.client.0.client_secret
}


data "auth0_tenant" "current" {}

output "AUTH0_ISSUER" {
  value     = "https://${data.auth0_tenant.current.domain}/"
}

output "AUTH0_AUDIENCE" {
  value     = auth0_resource_server.api.identifier
}

output "TEST_AUTH0_CLIENT_ID" {
  value     = var.create_auth0_api_test_client ? auth0_client.client[0].client_id : null
}

output "TEST_AUTH0_CLIENT_SECRET" {
  value = var.create_auth0_api_test_client ? {
    type   = "ssm"
    arn    = aws_ssm_parameter.test_client_secret.0.arn
    key    = aws_ssm_parameter.test_client_secret.0.name
    region = data.aws_region.current.name
  }: null
}

output "TEST_AUTH0_CLIENT_ACCESS_TOKEN_URL" {
  value     = var.create_auth0_api_test_client ? "https://${data.auth0_tenant.current.domain}/oauth/token" : null
}
