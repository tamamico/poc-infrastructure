resource "tfe_workspace" "terraform-teams" {
  name         = "terraform-teams"
  organization = data.tfe_organization.sagittec.name
  project_id   = data.tfe_project.confluent-cloud.id

  tags = {
    scope = "internal"
  }
}

data "confluent_service_account" "staging-admin" {
  display_name = "staging-admin"
}

resource "confluent_api_key" "staging-admin" {
  display_name = "Terraform - Teams"
  description  = "API key for Staging admin service account in teams workspace"

  owner {
    id          = data.confluent_service_account.staging-admin.id
    api_version = data.confluent_service_account.staging-admin.api_version
    kind        = data.confluent_service_account.staging-admin.kind
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_variable" "staging-admin-api-key" {
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.staging-admin.id
  category     = "env"
  description  = "Confluent Cloud API key"
  workspace_id = tfe_workspace.terraform-teams.id
}

resource "tfe_variable" "staging-admin-api-secret" {
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.staging-admin.secret
  category     = "env"
  sensitive    = true
  description  = "Confluent Cloud API secret"
  workspace_id = tfe_workspace.terraform-teams.id
}

variable "github_teams_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT to set-up in Teams workspace"
}

resource "tfe_variable" "github-token" {
  key          = "GITHUB_TOKEN"
  value        = var.github_teams_token
  category     = "env"
  sensitive    = true
  description  = "GitHub token"
  workspace_id = tfe_workspace.terraform-teams.id
}
