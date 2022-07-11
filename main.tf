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
  }
}

provider "random" {}
provider "auth0" {}

resource "random_pet" "api_name" {}

resource "auth0_resource_server" "api" {
  name        = random_pet.api_name.id
  identifier  = "https://${var.dream_project_id}.${var.dream_workspace}"
  signing_alg = "RS256"

  allow_offline_access                            = true
  skip_consent_for_verifiable_first_party_clients = true
}


data "auth0_tenant" "current" {}

output "AUTH0_ISSUER" {
  sensitive = true
  value     = "https://${data.auth0_tenant.current.domain}/"
}

output "AUTH0_AUDIENCE" {
  sensitive = true
  value     = auth0_resource_server.api.identifier
}
