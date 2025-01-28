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

data "confluent_kafka_cluster" "basic" {
  display_name = "poc_kafka_cluster"
  environment {
    id = data.confluent_environment.staging.id
  }
}

resource "confluent_api_key" "env-admin" {
  display_name = "env-admin-cluster-api-key"
  description  = "Environment manager cluster API Key"
  owner {
    id          = data.confluent_service_account.env-admin.id
    api_version = data.confluent_service_account.env-admin.api_version
    kind        = data.confluent_service_account.env-admin.kind
  }
  managed_resource {
    id          = data.confluent_kafka_cluster.basic.id
    api_version = data.confluent_kafka_cluster.basic.api_version
    kind        = data.confluent_kafka_cluster.basic.kind
    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

resource "confluent_kafka_topic" "input-men" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name       = "input.men.avro"
  partitions_count = 1
  rest_endpoint    = data.confluent_kafka_cluster.basic.rest_endpoint
  config = {
    "cleanup.policy" = "compact"
    "retention.ms"   = "3600000"
  }
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_topic" "input-women" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name       = "input.women.avro"
  partitions_count = 1
  rest_endpoint    = data.confluent_kafka_cluster.basic.rest_endpoint
  config = {
    "cleanup.policy" = "compact"
    "retention.ms"   = "3600000"
  }
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_topic" "output" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name       = "output.avro"
  partitions_count = 1
  rest_endpoint    = data.confluent_kafka_cluster.basic.rest_endpoint
  config = {
    "cleanup.policy" = "compact"
    "retention.ms"   = "3600000"
  }
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

data "confluent_service_account" "poc-user" {
  display_name = "poc-service-account"
}

resource "confluent_kafka_acl" "poc-user-input-men-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.input-men.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-user.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-user-input-women-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.input-women.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-user.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-user-output-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.output.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-user.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-user-consumer-group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "GROUP"
  resource_name = "poc"
  pattern_type  = "PREFIXED"
  principal     = "User:${data.confluent_service_account.poc-user.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

data "confluent_service_account" "poc-test" {
  display_name = "poc-test"
}

resource "confluent_kafka_acl" "poc-test-input-men-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.input-men.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-test.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-test-input-women-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.input-women.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-test.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-test-output-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.output.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${data.confluent_service_account.poc-test.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}

resource "confluent_kafka_acl" "poc-test-consumer-group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "GROUP"
  resource_name = "greeting-validator"
  pattern_type  = "PREFIXED"
  principal     = "User:${data.confluent_service_account.poc-test.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin.id
    secret = confluent_api_key.env-admin.secret
  }
}
