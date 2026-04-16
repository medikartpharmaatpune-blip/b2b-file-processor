variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}
