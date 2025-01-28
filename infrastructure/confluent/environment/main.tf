terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.13.0"
    }
  }
}

resource "confluent_environment" "staging" {
  display_name = "staging"

  stream_governance {
    package = "ESSENTIALS"
  }
}

resource "confluent_service_account" "env-admin" {
  display_name = "env-admin"
  description  = "Environment admin service account created by Terraform"
}

resource "confluent_role_binding" "env-admin" {
  principal   = "User:${confluent_service_account.env-admin.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.staging.resource_name
}

resource "confluent_kafka_cluster" "basic" {
  display_name = "poc_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-1"
  basic {}
  environment {
    id = confluent_environment.staging.id
  }
}

resource "confluent_service_account" "poc-user" {
  display_name = "poc-service-account"
  description  = "Service account for PoC application"
}

resource "confluent_api_key" "cluster-poc-user" {
  display_name = "cluster-poc-service-account"
  description  = "Cluster API Key that is owned by 'poc-service-account' account"
  owner {
    id          = confluent_service_account.poc-user.id
    api_version = confluent_service_account.poc-user.api_version
    kind        = confluent_service_account.poc-user.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}

resource "confluent_service_account" "poc-test" {
  display_name = "poc-test"
  description  = "Service account to test PoC application"
}

resource "confluent_api_key" "cluster-poc-test" {
  display_name = "cluster-poc-test"
  description  = "Cluster API Key that is owned by 'poc-test' account"
  owner {
    id          = confluent_service_account.poc-test.id
    api_version = confluent_service_account.poc-test.api_version
    kind        = confluent_service_account.poc-test.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}
