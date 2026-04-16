variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "input_bucket_name" {
  type = string
}

variable "gcs_service_account_email" {
  type = string
}

variable "ack_deadline_seconds" {
  type    = number
  default = 20
}

variable "max_delivery_attempts" {
  type    = number
  default = 5
}

variable "min_backoff_seconds" {
  type    = number
  default = 10
}

variable "max_backoff_seconds" {
  type    = number
  default = 300
}
