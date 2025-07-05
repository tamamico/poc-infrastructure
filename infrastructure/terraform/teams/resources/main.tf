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

data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_team" "team" {
  name         = "owners"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_team_token" "github-actions" {
  team_id     = data.tfe_team.team.id
  description = "GitHub Actions token for team ${var.name}"
}

data "github_repository" "team" {
  full_name = var.repository
}

resource "github_actions_secret" "terraform-token" {
  repository      = data.github_repository.team.name
  secret_name     = "TF_TOKEN"
  plaintext_value = tfe_team_token.github-actions.token
}

resource "github_actions_variable" "terraform-organization" {
  repository    = data.github_repository.team.name
  variable_name = "TF_ORGANIZATION"
  value         = "sagittec"
}

resource "tfe_workspace" "workspace" {
  name         = "workspace-${var.name}"
  organization = data.tfe_organization.sagittec.name

  tags = {
    environment = "staging"
  }
}

resource "github_actions_variable" "terraform-workspace" {
  repository    = data.github_repository.team.name
  variable_name = "TF_WORKSPACE"
  value         = tfe_workspace.workspace.name
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

resource "confluent_service_account" "team-admin" {
  display_name = "${var.name}-${data.confluent_environment.staging.display_name}"
  description  = "Service Account for team ${var.name} in ${data.confluent_environment.staging.display_name}"
}

resource "confluent_api_key" "team-admin" {
  display_name = "${var.name}-${data.confluent_environment.staging.display_name}"
  description  = "API Key for ${confluent_service_account.team-admin.display_name} service account"

  owner {
    id          = confluent_service_account.team-admin.id
    api_version = confluent_service_account.team-admin.api_version
    kind        = confluent_service_account.team-admin.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.staging.id
    api_version = data.confluent_kafka_cluster.staging.api_version
    kind        = data.confluent_kafka_cluster.staging.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

resource "confluent_kafka_acl" "create-topics" {
  resource_type = "TOPIC"
  resource_name = "es.ecristobal.${var.name}"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.team-admin.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
}

resource "tfe_variable" "staging-broker-id" {
  key          = "KAFKA_ID"
  value        = data.confluent_kafka_cluster.staging.id
  category     = "env"
  description  = "Staging Kafka broker ID"
  workspace_id = tfe_workspace.workspace.id
}

resource "tfe_variable" "staging-broker-rest-endpoint" {
  key          = "KAFKA_REST_ENDPOINT"
  value        = data.confluent_kafka_cluster.staging.rest_endpoint
  category     = "env"
  description  = "Staging Kafka broker REST endpoint"
  workspace_id = tfe_workspace.workspace.id
}

resource "tfe_variable" "staging-admin-api-key" {
  key          = "KAFKA_API_KEY"
  value        = confluent_api_key.team-admin.id
  category     = "env"
  description  = "${var.name} admin API key"
  workspace_id = tfe_workspace.workspace.id
}

resource "tfe_variable" "staging-admin-api-secret" {
  key          = "KAFKA_API_SECRET"
  value        = confluent_api_key.team-admin.secret
  category     = "env"
  sensitive    = true
  description  = "${var.name} admin API secret"
  workspace_id = tfe_workspace.workspace.id
}
