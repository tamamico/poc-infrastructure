variable "staging_id" {
  type        = string
  nullable    = false
  description = "Staging environment ID"
}

module "teams" {
  for_each       = local.teams
  source         = "./resources"
  name           = each.key
  repository     = each.value.repository
  environment-id = var.staging_id
}
