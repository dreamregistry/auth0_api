variable "dream_project_id" {
  type = string
}

variable "dream_workspace" {
  type = string
}

variable "create_auth0_api_test_client" {
  type    = bool
  default = false
}

variable "scopes" {
  type = set(object({
    value       = string,
    description = string
  }))
  default = []
}
