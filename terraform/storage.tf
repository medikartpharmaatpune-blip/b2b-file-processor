# Input bucket — incoming files from trading partners
resource "google_storage_bucket" "input" {
  name          = "${var.project_id}-b2b-input-${var.environment}"
  location      = var.region
  force_destroy = true   # allow terraform destroy to delete bucket with files

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 30 }   # delete raw files after 30 days
    action    { type = "Delete" }
  }

  labels = {
    environment = var.environment
    purpose     = "b2b-input"
  }
}

# Output bucket — processed files
resource "google_storage_bucket" "output" {
  name          = "${var.project_id}-b2b-output-${var.environment}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 90 }   # keep processed files for 90 days
    action    { type = "Delete" }
  }

  labels = {
    environment = var.environment
    purpose     = "b2b-output"
  }
}

output "input_bucket_name" {
  value = google_storage_bucket.input.name
}

output "output_bucket_name" {
  value = google_storage_bucket.output.name
}
