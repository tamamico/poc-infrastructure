terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.13.0"
    }
  }
}

data "confluent_environment" "staging" {
  display_name = "staging"
}

data "confluent_service_account" "env-admin" {
  display_name = "env-admin"
}

data "confluent_schema_registry_cluster" "schema-registry" {
  environment {
    id = data.confluent_environment.staging.id
  }
}

resource "confluent_api_key" "env-admin" {
  display_name = "env-admin-schema-registry-api-key"
  description  = "Environment manager schema registry API Key"
  owner {
    id          = data.confluent_service_account.env-admin.id
    api_version = data.confluent_service_account.env-admin.api_version
    kind        = data.confluent_service_account.env-admin.kind
  }
  managed_resource {
    id          = data.confluent_schema_registry_cluster.schema-registry.id
    api_version = data.confluent_schema_registry_cluster.schema-registry.api_version
    kind        = data.confluent_schema_registry_cluster.schema-registry.kind
    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

resource "confluent_schema" "input" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema-registry.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.schema-registry.rest_endpoint
  subject_name  = "es.ecristobal.poc.scs.avro.Input"
  format        = "AVRO"
  schema = file("./input.avsc")
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_subject_config" "input" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema-registry.id
  }
  subject_name        = confluent_schema.input.subject_name
  compatibility_level = "FORWARD_TRANSITIVE"
  rest_endpoint       = data.confluent_schema_registry_cluster.schema-registry.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_schema" "output" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema-registry.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.schema-registry.rest_endpoint
  subject_name  = "es.ecristobal.poc.scs.avro.Output"
  format        = "AVRO"
  schema = file("./output.avsc")
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_subject_config" "output" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema-registry.id
  }
  subject_name        = confluent_schema.output.subject_name
  compatibility_level = "FORWARD_TRANSITIVE"
  rest_endpoint       = data.confluent_schema_registry_cluster.schema-registry.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

data "confluent_service_account" "poc-user" {
  display_name = "poc-service-account"
}

resource "confluent_role_binding" "poc-user-schema-registry" {
  principal   = "User:${data.confluent_service_account.poc-user.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.schema-registry.resource_name}/subject=es.ecristobal.poc.scs.avro.*"
}

resource "confluent_api_key" "schema-registry-poc-user" {
  display_name = "schema-registry-poc-service-account"
  description  = "Schema Registry API Key that is owned by 'poc-service-account' account"
  owner {
    id          = data.confluent_service_account.poc-user.id
    api_version = data.confluent_service_account.poc-user.api_version
    kind        = data.confluent_service_account.poc-user.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.schema-registry.id
    api_version = data.confluent_schema_registry_cluster.schema-registry.api_version
    kind        = data.confluent_schema_registry_cluster.schema-registry.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

data "confluent_service_account" "poc-test" {
  display_name = "poc-test"
}

resource "confluent_role_binding" "poc-test-schema-registry" {
  principal   = "User:${data.confluent_service_account.poc-test.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.schema-registry.resource_name}/subject=es.ecristobal.poc.scs.avro.*"
}

resource "confluent_api_key" "schema-registry-poc-test" {
  display_name = "schema-registry-poc-test"
  description  = "Schema Registry API Key that is owned by 'poc-test' account"
  owner {
    id          = data.confluent_service_account.poc-test.id
    api_version = data.confluent_service_account.poc-test.api_version
    kind        = data.confluent_service_account.poc-test.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.schema-registry.id
    api_version = data.confluent_schema_registry_cluster.schema-registry.api_version
    kind        = data.confluent_schema_registry_cluster.schema-registry.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}
