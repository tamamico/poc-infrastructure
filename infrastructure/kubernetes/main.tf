provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

data "terraform_remote_state" "environment" {
  backend = "remote"

  config = {
    organization = "tamamico"
    workspaces = {
      name = "kafka-environment"
    }
  }
}

data "terraform_remote_state" "schema-registry" {
  backend = "remote"

  config = {
    organization = "tamamico"
    workspaces = {
      name = "kafka-schema-registry"
    }
  }
}

data "kubernetes_namespace" "poc" {
  metadata {
    name = "poc"
  }
}

resource "kubernetes_config_map" "poc-settings" {
  metadata {
    name      = "settings"
    namespace = data.kubernetes_namespace.poc.id
  }

  data = {
    "spring.cloud.stream.kafka.binder.brokers"                           = data.terraform_remote_state.environment.outputs.kafka-bootstrap-server
    "spring.cloud.stream.kafka.binder.configuration.schema.registry.url" = data.terraform_remote_state.schema-registry.outputs.schema-registry-url
    "kafka.user"                                                         = data.terraform_remote_state.environment.outputs.poc-username
    "schema-registry.user"                                               = data.terraform_remote_state.schema-registry.outputs.poc-username
  }
}

resource "kubernetes_secret" "secrets" {
  metadata {
    name      = "secrets"
    namespace = "poc"
  }

  data = {
    "kafka.password"           = data.terraform_remote_state.environment.outputs.poc-password
    "schema-registry.password" = data.terraform_remote_state.schema-registry.outputs.poc-password
  }
}
