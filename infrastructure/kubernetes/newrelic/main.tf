provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

variable "key" {
  type     = string
  nullable = false
}

data "kubernetes_namespace" "newrelic" {
  metadata {
    name = "newrelic"
  }
}

resource "kubernetes_config_map" "settings" {
  metadata {
    name      = "settings"
    namespace = data.kubernetes_namespace.newrelic.id
  }

  data = {
    "newrelic-infrastructure.enabled"      = true
    "nri-prometheus.enabled"               = false
    "nri-metadata-injection.enabled"       = true
    "kube-state-metrics.enabled"           = true
    "nri-kube-events.enabled"              = true
    "newrelic-logging.enabled"             = true
    "newrelic-pixie.enabled"               = false
    "pixie-chart.enabled"                  = false
    "newrelic-infra-operator.enabled"      = false
    "newrelic-prometheus-agent.enabled"    = true
    "k8s-agents-operator.enabled"          = true
    "newrelic-k8s-metrics-adapter.enabled" = false
    "global.cluster"                       = "Docker Desktop"
    "global.insightsKey"                   = ""
    "global.customSecretName"              = ""
    "global.customSecretLicenseKey"        = ""
    "global.images.registry"               = ""
    "global.priorityClassName"             = ""
    "global.lowDataMode"                   = true
    "global.privileged"                    = true
  }
}

resource "kubernetes_secret" "secrets" {
  metadata {
    name      = "secrets"
    namespace = "newrelic"
  }

  data = {
    "global.licenseKey" = var.key
  }
}
