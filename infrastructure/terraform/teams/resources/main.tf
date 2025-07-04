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

data "tfe_team" "team" {
  name         = "owners"
  organization = "sagittec"
}

resource "tfe_team_token" "github-actions" {
  team_id     = data.tfe_team.team.id
  description = "GitHub Actions token for team ${var.name}"
}

data "github_repository" "team" {
  full_name = var.repository
}

resource "github_actions_secret" "example_secret" {
  repository      = data.github_repository.team.name
  secret_name     = "TF_TOKEN"
  plaintext_value = tfe_team_token.github-actions.token
}
