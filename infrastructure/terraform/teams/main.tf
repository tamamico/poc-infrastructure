terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.67.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.23.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.0"
    }
  }
}

data "confluent_environment" "staging" {
  display_name = "staging"
}

data "confluent_kafka_cluster" "staging" {
  display_name = "poc_kafka_cluster"

  environment {
    id = data.confluent_environment.staging.id
  }
}

data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_team" "team" {
  name         = "owners"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_team_token" "github-actions" {
  for_each    = local.teams
  team_id     = data.tfe_team.team.id
  description = "GitHub Actions token for team ${each.key}"
}

data "github_repository" "team" {
  for_each  = local.teams
  full_name = each.value.repository
}

resource "github_actions_secret" "terraform-token" {
  for_each        = local.teams
  repository      = data.github_repository.team[each.key].name
  secret_name     = "TF_TOKEN"
  plaintext_value = tfe_team_token.github-actions[each.key].token
}

resource "github_actions_variable" "terraform-organization" {
  for_each      = local.teams
  repository    = data.github_repository.team[each.key].name
  variable_name = "TF_ORGANIZATION"
  value         = "sagittec"
}

resource "tfe_workspace" "workspace" {
  for_each     = local.teams
  name         = "workspace-${each.key}"
  organization = data.tfe_organization.sagittec.name

  tags = {
    environment = "staging"
  }
}

resource "github_actions_variable" "terraform-workspace" {
  for_each      = local.teams
  repository    = data.github_repository.team[each.key].name
  variable_name = "TF_WORKSPACE"
  value         = tfe_workspace.workspace[each.key].name
}

resource "confluent_service_account" "team-admin" {
  for_each     = local.teams
  display_name = "${each.key}-${data.confluent_environment.staging.display_name}"
  description  = "Service Account for team ${each.key} in ${data.confluent_environment.staging.display_name}"
}

resource "confluent_role_binding" "team-admin-topics" {
  for_each    = local.teams
  principal   = "User:${confluent_service_account.team-admin[each.key].id}"
  role_name   = "ResourceOwner"
  crn_pattern = "crn://confluent.cloud/kafka=${data.confluent_kafka_cluster.staging.id}/topic=es.ecristobal.${each.key}*"
}

resource "confluent_api_key" "team-admin" {
  for_each     = local.teams
  display_name = "${each.key}-${data.confluent_environment.staging.display_name}"
  description  = "API Key for ${confluent_service_account.team-admin[each.key].display_name} service account"

  owner {
    id          = confluent_service_account.team-admin[each.key].id
    api_version = confluent_service_account.team-admin[each.key].api_version
    kind        = confluent_service_account.team-admin[each.key].kind
  }
}

resource "tfe_variable" "team-admin-api-key" {
  for_each     = local.teams
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.team-admin[each.key].id
  category     = "env"
  description  = "${each.key} admin API key"
  workspace_id = tfe_workspace.workspace[each.key].id
}

resource "tfe_variable" "team-admin-api-secret" {
  for_each     = local.teams
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.team-admin[each.key].secret
  category     = "env"
  sensitive    = true
  description  = "${each.key} admin API secret"
  workspace_id = tfe_workspace.workspace[each.key].id
}
