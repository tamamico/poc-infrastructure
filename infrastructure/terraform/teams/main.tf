module "teams" {
  for_each       = local.teams
  source         = "./resources"
  name           = each.key
  repository     = each.value.repository
}
