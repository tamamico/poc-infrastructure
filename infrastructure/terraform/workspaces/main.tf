terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.67.0"
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

resource "tfe_workspace_settings" "confluent-environment" {
  workspace_id = tfe_workspace.confluent-environment.id
}
