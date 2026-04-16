resource "google_storage_bucket" "input" {
  name          = "${var.project_id}-b2b-input-${var.environment}"
  location      = var.region
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = var.input_retention_days }
    action    { type = "Delete" }
  }

  labels = {
    environment = var.environment
    purpose     = "b2b-input"
    managed_by  = "terraform"
  }
}

resource "google_storage_bucket" "output" {
  name          = "${var.project_id}-b2b-output-${var.environment}"
  location      = var.region
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = var.output_retention_days }
    action    { type = "Delete" }
  }

  labels = {
    environment = var.environment
    purpose     = "b2b-output"
    managed_by  = "terraform"
  }
}
