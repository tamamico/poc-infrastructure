resource "tfe_workspace" "terraform-teams" {
  name         = "terraform-teams"
  organization = data.tfe_organization.sagittec.name
  project_id   = data.tfe_project.confluent-cloud.id

  tags = {
    scope = "internal"
  }
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT to set-up in Teams workspace"
}

resource "tfe_variable" "github-token" {
  key          = "GITHUB_TOKEN"
  value        = var.github_token
  category     = "env"
  sensitive    = true
  description  = "GitHub token"
  workspace_id = tfe_workspace.terraform-teams.id
}

data "tfe_team" "team" {
  name         = "owners"
  organization = data.tfe_organization.sagittec.name
}

resource "tfe_team_token" "teams" {
  team_id     = data.tfe_team.team.id
  description = "Terraform token for teams workspace"
}

resource "tfe_variable" "teams" {
  key          = "TFE_TOKEN"
  value        = tfe_team_token.teams.token
  category     = "env"
  sensitive    = true
  description  = "Terraform Cloud token"
  workspace_id = tfe_workspace.terraform-teams.id
}
