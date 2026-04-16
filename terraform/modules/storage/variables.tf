variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "input_retention_days" {
  type    = number
  default = 30
}

variable "output_retention_days" {
  type    = number
  default = 90
}
