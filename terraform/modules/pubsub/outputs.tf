output "topic_name"        { value = google_pubsub_topic.file_events.name }
output "subscription_name" { value = google_pubsub_subscription.file_events.name }
output "dead_letter_topic" { value = google_pubsub_topic.dead_letter.name }
