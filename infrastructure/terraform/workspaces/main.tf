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
  }
}

data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_project" "confluent-cloud" {
  name         = "confluent-cloud"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_workspace" "confluent-environment" {
  name         = "confluent-environment"
  organization = data.tfe_organization.sagittec.name
  project_id   = data.tfe_project.confluent-cloud.id

  tags = {
    environment = "staging"
  }
}

data "confluent_organization" "confluent" {}

data "confluent_service_account" "automator" {
  id = "sa-1223xpv"
}

resource "confluent_role_binding" "staging-admin" {
  principal   = "User:${data.confluent_service_account.automator.id}"
  role_name   = "AccountAdmin"
  crn_pattern = data.confluent_organization.confluent.resource_name
}

resource "confluent_api_key" "automator" {
  display_name = "Terraform - Environment"
  description  = "API key for Automator service account to use in Terraform Cloud"

  owner {
    id          = data.confluent_service_account.automator.id
    api_version = data.confluent_service_account.automator.api_version
    kind        = data.confluent_service_account.automator.kind
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_variable" "confluent-api-key" {
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.automator.id
  category     = "env"
  description  = "Confluent Cloud API key"
  workspace_id = tfe_workspace.confluent-environment.id
}

resource "tfe_variable" "confluent-api-secret" {
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.automator.secret
  category     = "env"
  sensitive    = true
  description  = "Confluent Cloud API secret"
  workspace_id = tfe_workspace.confluent-environment.id
}
