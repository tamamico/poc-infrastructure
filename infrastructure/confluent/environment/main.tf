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

resource "tfe_variable" "kafka-id" {
  key          = "KAFKA_ID"
  value        = confluent_kafka_cluster.poc.id
  category     = "env"
  description  = "Staging cluster ID"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "kafka-rest-endpoint" {
  key          = "KAFKA_REST_ENDPOINT"
  value        = confluent_kafka_cluster.poc.rest_endpoint
  category     = "env"
  description  = "Staging cluster ID"
  workspace_id = data.tfe_workspace.teams.id
}

resource "confluent_service_account" "staging-admin" {
  display_name = "staging-admin"
  description  = "Staging admin service account"
}

data "confluent_organization" "sagittec" {}

resource "confluent_role_binding" "staging-admin-account" {
  for_each = toset(["AccountAdmin", "ResourceKeyAdmin"])
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = each.key
  crn_pattern = data.confluent_organization.sagittec.resource_name
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

data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_workspace" "teams" {
  name         = "terraform-teams"
  organization = data.tfe_organization.sagittec.name
}

resource "confluent_api_key" "staging-admin-cloud" {
  display_name = "staging-admin-cloud"
  description  = "API key for staging admin service account"

  owner {
    id          = confluent_service_account.staging-admin.id
    api_version = confluent_service_account.staging-admin.api_version
    kind        = confluent_service_account.staging-admin.kind
  }
}

resource "tfe_variable" "confluent-api-key" {
  key          = "CONFLUENT_CLOUD_API_KEY"
  value        = confluent_api_key.staging-admin-cloud.id
  category     = "env"
  description  = "Confluent Cloud API key"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "confluent-api-secret" {
  key          = "CONFLUENT_CLOUD_API_SECRET"
  value        = confluent_api_key.staging-admin-cloud.secret
  category     = "env"
  sensitive    = true
  description  = "Confluent Cloud API secret"
  workspace_id = data.tfe_workspace.teams.id
}

resource "confluent_api_key" "staging-admin-kafka" {
  display_name = "staging-admin-kafka"
  description  = "API key for staging admin service account"

  owner {
    id          = confluent_service_account.staging-admin.id
    api_version = confluent_service_account.staging-admin.api_version
    kind        = confluent_service_account.staging-admin.kind
  }

  managed_resource {
    api_version = confluent_kafka_cluster.poc.api_version
    id          = confluent_kafka_cluster.poc.id
    kind        = confluent_kafka_cluster.poc.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}

resource "tfe_variable" "kafka-api-key" {
  key          = "KAFKA_API_KEY"
  value        = confluent_api_key.staging-admin-kafka.id
  category     = "env"
  description  = "Kafka API key"
  workspace_id = data.tfe_workspace.teams.id
}

resource "tfe_variable" "kafka-api-secret" {
  key          = "KAFKA_API_SECRET"
  value        = confluent_api_key.staging-admin-kafka.secret
  category     = "env"
  sensitive    = true
  description  = "Kafka API secret"
  workspace_id = data.tfe_workspace.teams.id
}
