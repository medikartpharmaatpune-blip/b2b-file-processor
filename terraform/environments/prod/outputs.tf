output "input_bucket" {
  value = module.storage.input_bucket_name
}

output "output_bucket" {
  value = module.storage.output_bucket_name
}

output "pubsub_topic" {
  value = module.pubsub.topic_name
}

output "pubsub_subscription" {
  value = module.pubsub.subscription_name
}

output "gke_cluster" {
  value = module.gke.cluster_name
}

output "service_account" {
  value = module.iam.service_account_email
}
