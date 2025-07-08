variable "name" {
  type        = string
  nullable    = false
  description = "Team name"
}

variable "repositories" {
  type = set(string)
  nullable    = false
  description = "Team repositories to set-up Terraform token"
}
