resource "google_service_account" "b2b_processor" {
  account_id   = "b2b-processor-${var.environment}"
  display_name = "B2B File Processor (${var.environment})"
  description  = "Used by the b2b-processor pod on GKE"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "input_reader" {
  bucket = var.input_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

resource "google_storage_bucket_iam_member" "output_writer" {
  bucket = var.output_bucket_name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.b2b_processor.email}"
}

resource "google_pubsub_topic_iam_member" "viewer" {
  topic  = var.pubsub_topic_name
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.b2b_processor.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/b2b-processor]"
  depends_on         = [var.gke_cluster_dependency]
}
