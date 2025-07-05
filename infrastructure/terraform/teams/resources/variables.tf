variable "name" {
  type        = string
  nullable    = false
  description = "Team name"
}

variable "repository" {
  type        = string
  nullable    = false
  description = "GitHub repository to set-up API key secrets"
}

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
