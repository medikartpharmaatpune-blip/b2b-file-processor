# Service account for the b2b processor
resource "google_service_account" "b2b_processor" {
  account_id   = "b2b-processor-${var.environment}"
  display_name = "B2B File Processor Service Account"
  description  = "Used by the b2b-processor pod on GKE"
}

# Allow processor to read from input bucket
resource "google_storage_bucket_iam_member" "processor_input_reader" {
  bucket = google_storage_bucket.input.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

# Allow processor to write to output bucket
resource "google_storage_bucket_iam_member" "processor_output_writer" {
  bucket = google_storage_bucket.output.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

# Allow processor to subscribe to Pub/Sub
resource "google_pubsub_subscription_iam_member" "processor_subscriber" {
  subscription = google_pubsub_subscription.file_events.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.b2b_processor.email}"
}

# Allow processor to acknowledge Pub/Sub messages
resource "google_pubsub_topic_iam_member" "processor_viewer" {
  topic  = google_pubsub_topic.file_events.name
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.b2b_processor.email}"
}

output "service_account_email" {
  value = google_service_account.b2b_processor.email
}
