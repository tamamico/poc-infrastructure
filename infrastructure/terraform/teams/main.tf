module "teams" {
  for_each     = local.teams
  source       = "./resources"
  name         = each.key
  repositories = each.value.repositories
}
