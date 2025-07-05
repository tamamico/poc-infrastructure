variable "staging_admin_key" {
  type        = string
  nullable    = false
  description = "Staging admin key"
}

variable "staging_admin_secret" {
  type        = string
  nullable    = false
  description = "Staging admin secret"
}

module "teams" {
  for_each             = local.teams
  source               = "./resources"
  name                 = each.key
  repository           = each.value.repository
  staging_admin_key    = var.staging_admin_key
  staging_admin_secret = var.staging_admin_secret
}
