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
    github = {
      source  = "integrations/github"
      version = "6.0"
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
