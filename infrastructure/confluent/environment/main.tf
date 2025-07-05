terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.23.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.67.0"
    }
  }
}

resource "confluent_environment" "staging" {
  display_name = "staging"

  stream_governance {
    package = "ESSENTIALS"
  }
}

resource "confluent_kafka_cluster" "poc" {
  display_name = "poc_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-1"
  basic {}
  environment {
    id = confluent_environment.staging.id
  }
}

resource "confluent_service_account" "staging-admin" {
  display_name = "staging-admin"
  description  = "Staging admin service account"
}

resource "confluent_api_key" "staging-admin" {
  display_name = "staging-admin"
  description  = "API key for staging admin service account"

  owner {
    id          = confluent_service_account.staging-admin.id
    api_version = confluent_service_account.staging-admin.api_version
    kind        = confluent_service_account.staging-admin.kind
  }
}

resource "confluent_role_binding" "staging-admin-environment" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.staging.resource_name
}

resource "confluent_role_binding" "staging-admin-cluster" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.poc.rbac_crn
}

data "confluent_organization" "sagittec" {}

resource "confluent_role_binding" "staging-admin-account" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "AccountAdmin"
  crn_pattern = data.confluent_organization.sagittec.resource_name
}

resource "confluent_role_binding" "staging-admin-key" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "ResourceKeyAdmin"
  crn_pattern = data.confluent_organization.sagittec.resource_name
}

data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_workspace" "teams" {
  name         = "terraform-teams"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_variable" "confluent-api-key" {
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.staging-admin.id
  category     = "env"
  description  = "Confluent Cloud API key"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "confluent-api-secret" {
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.staging-admin.secret
  category     = "env"
  sensitive    = true
  description  = "Confluent Cloud API secret"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "kafka-api-key" {
  key          = "TF_VAR_staging_admin_key"
  value        = confluent_api_key.staging-admin.id
  category     = "env"
  description  = "Kafka API key"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "kafka-api-secret" {
  key          = "TF_VAR_staging_admin_secret"
  value        = confluent_api_key.staging-admin.secret
  category     = "env"
  sensitive    = true
  description  = "KAFKA API secret"
  workspace_id = data.tfe_workspace.teams.id
}
