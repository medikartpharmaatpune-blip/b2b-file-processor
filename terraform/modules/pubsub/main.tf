resource "google_pubsub_topic" "file_events" {
  name    = "b2b-file-events-${var.environment}"
  project = var.project_id
  labels  = { environment = var.environment }
}

resource "google_pubsub_topic" "dead_letter" {
  name    = "b2b-file-events-dead-letter-${var.environment}"
  project = var.project_id
}

resource "google_pubsub_subscription" "file_events" {
  name    = "b2b-file-events-sub-${var.environment}"
  topic   = google_pubsub_topic.file_events.name
  project = var.project_id

  ack_deadline_seconds = var.ack_deadline_seconds

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  retry_policy {
    minimum_backoff = "${var.min_backoff_seconds}s"
    maximum_backoff = "${var.max_backoff_seconds}s"
  }

  labels = { environment = var.environment }
}

resource "google_pubsub_subscription" "dead_letter" {
  name    = "b2b-file-events-dead-letter-sub-${var.environment}"
  topic   = google_pubsub_topic.dead_letter.name
  project = var.project_id
  ack_deadline_seconds = 60
}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  topic  = google_pubsub_topic.file_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.gcs_service_account_email}"
}

resource "google_storage_notification" "file_trigger" {
  bucket         = var.input_bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.file_events.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_member.gcs_publisher]
}
