terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.23.0"
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

resource "confluent_role_binding" "staging-environment-admin" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.staging.resource_name
}

resource "confluent_role_binding" "staging-environment-operator" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "Operator"
  crn_pattern = confluent_environment.staging.resource_name
}

resource "confluent_role_binding" "staging-topic-admin" {
  principal   = "User:${confluent_service_account.staging-admin.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.poc.rbac_crn
}
