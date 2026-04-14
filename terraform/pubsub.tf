# Topic — GCS publishes here when a file arrives
resource "google_pubsub_topic" "file_events" {
  name = "b2b-file-events-${var.environment}"

  labels = {
    environment = var.environment
  }
}

# Subscription — your processor subscribes to this
resource "google_pubsub_subscription" "file_events" {
  name  = "b2b-file-events-sub-${var.environment}"
  topic = google_pubsub_topic.file_events.name

  ack_deadline_seconds = 20

  # Dead-letter: after 5 failed deliveries, move to dead-letter topic
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }

  labels = {
    environment = var.environment
  }
}

# Dead-letter topic — failed messages land here for investigation
resource "google_pubsub_topic" "dead_letter" {
  name = "b2b-file-events-dead-letter-${var.environment}"
}

# Dead-letter subscription — so you can inspect failed messages
resource "google_pubsub_subscription" "dead_letter" {
  name  = "b2b-file-events-dead-letter-sub-${var.environment}"
  topic = google_pubsub_topic.dead_letter.name

  ack_deadline_seconds = 60
}

# GCS notification — fires Pub/Sub when a file is uploaded
resource "google_storage_notification" "file_trigger" {
  bucket         = google_storage_bucket.input.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.file_events.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publisher]
}

# Allow GCS to publish to Pub/Sub
data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  topic  = google_pubsub_topic.file_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

output "pubsub_topic" {
  value = google_pubsub_topic.file_events.name
}

output "pubsub_subscription" {
  value = google_pubsub_subscription.file_events.name
}
