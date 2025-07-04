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

variable "environment-id" {
  type        = string
  nullable    = false
  description = "Environment ID"
}
