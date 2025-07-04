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

data "tfe_team" "team" {
  name         = "owners"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_team_token" "github-actions" {
  team_id     = data.tfe_team.team.id
  description = "GitHub Actions token for team ${var.name}"
}

data "github_repository" "team" {
  full_name = var.repository
}

resource "github_actions_secret" "terraform-token" {
  repository      = data.github_repository.team.name
  secret_name     = "TF_TOKEN"
  plaintext_value = tfe_team_token.github-actions.token
}

resource "github_actions_variable" "terraform-organization" {
  repository    = data.github_repository.team.name
  variable_name = "TF_ORGANIZATION"
  value         = "sagittec"
}

resource "tfe_workspace" "workspace" {
  name         = "workspace-${var.name}"
  organization = data.tfe_organization.sagittec.name

  tags = {
    environment = "staging"
  }
}

resource "github_actions_variable" "terraform-workspace" {
  repository    = data.github_repository.team.name
  variable_name = "TF_WORKSPACE"
  value         = tfe_workspace.workspace.name
}
