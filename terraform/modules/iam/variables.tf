variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "input_bucket_name" {
  type = string
}

variable "output_bucket_name" {
  type = string
}

variable "pubsub_subscription_name" {
  type = string
}

variable "pubsub_topic_name" {
  type = string
}

variable "gke_cluster_dependency" {
  type    = any
  default = null
}
