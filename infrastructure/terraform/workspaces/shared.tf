data "tfe_organization" "sagittec" {
  name = "sagittec"
}

data "tfe_project" "confluent-cloud" {
  name         = "confluent-cloud"
  organization = data.tfe_organization.sagittec.name
}
