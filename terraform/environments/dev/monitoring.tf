resource "google_monitoring_dashboard" "b2b_processor" {
  dashboard_json = jsonencode({
    displayName = "B2B File Processor — ${var.environment}"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub message backlog"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-sub-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "60s",
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "messages", scale = "LINEAR" }
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Dead-letter queue depth"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-dead-letter-sub-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "60s",
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "messages", scale = "LINEAR" }
            }
          }
        },
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Messages acknowledged per minute"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"pubsub.googleapis.com/subscription/num_messages_sent\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-sub-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "60s",
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "msgs/min", scale = "LINEAR" }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Pod restarts"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/container/restart_count\" AND resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"b2b-cluster-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "60s",
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "restarts/min", scale = "LINEAR" }
            }
          }
        },
        {
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "GCS input bucket size"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"storage.googleapis.com/storage/total_bytes\" AND resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${var.project_id}-b2b-input-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "3600s",
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "bytes", scale = "LINEAR" }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Message oldest unacked age"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-sub-${var.environment}\""
                    aggregation = {
                      alignmentPeriod  = "60s",
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "seconds", scale = "LINEAR" }
            }
          }
        }
      ]
    }
  })
}

resource "google_monitoring_alert_policy" "dead_letter_alert" {
  display_name = "B2B dead-letter queue has messages (${var.environment})"
  combiner     = "OR"

  conditions {
    display_name = "Dead-letter queue depth > 0"
    condition_threshold {
      filter          = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-dead-letter-sub-${var.environment}\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "processor_errors" {
  display_name = "B2B Pub/Sub message backlog elevated (${var.environment})"
  combiner     = "OR"

  conditions {
    display_name = "Message backlog > 10"
    condition_threshold {
      filter          = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"b2b-file-events-sub-${var.environment}\""
      duration        = "120s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "B2B processor alerts — email"
  type         = "email"

  labels = {
    email_address = "medikartpharmaatpune@gmail.com"
  }
}
