resource "tfe_workspace" "confluent-environment" {
  name         = "confluent-environment"
  organization = data.tfe_organization.sagittec.name
  project_id   = data.tfe_project.confluent-cloud.id

  tags = {
    environment = "staging"
  }
}

data "confluent_organization" "confluent" {}

resource "confluent_service_account" "terraform" {
  display_name = "terraform"
  description  = "Main Terraform Cloud service account"
}

data "confluent_organization" "sagittec" {}

resource "confluent_role_binding" "terraform-admin-organization" {
  principal   = "User:${confluent_service_account.terraform.id}"
  role_name   = "OrganizationAdmin"
  crn_pattern = data.confluent_organization.sagittec.resource_name
}

resource "confluent_api_key" "terraform" {
  display_name = "Terraform - Environment"
  description  = "API key for Terraform service account and environment workspace"

  owner {
    id          = confluent_service_account.terraform.id
    api_version = confluent_service_account.terraform.api_version
    kind        = confluent_service_account.terraform.kind
  }
}

resource "tfe_variable" "terraform-api-key" {
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.terraform.id
  category     = "env"
  description  = "Confluent Cloud API key"
  workspace_id = tfe_workspace.confluent-environment.id
}

resource "tfe_variable" "terraform-api-secret" {
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.terraform.secret
  category     = "env"
  sensitive    = true
  description  = "Confluent Cloud API secret"
  workspace_id = tfe_workspace.confluent-environment.id
}

resource "tfe_team_token" "confluent" {
  team_id     = data.tfe_team.team.id
  description = "Terraform token for confluent workspace"
}

resource "tfe_variable" "confluent" {
  key          = "TFE_TOKEN"
  value        = tfe_team_token.confluent.token
  category     = "env"
  sensitive    = true
  description  = "Terraform Cloud token"
  workspace_id = tfe_workspace.confluent-environment.id
}
