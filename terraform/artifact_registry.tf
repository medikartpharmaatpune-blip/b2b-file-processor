resource "google_artifact_registry_repository" "b2b_processor" {
  location      = var.region
  repository_id = "b2b-processor"
  description   = "B2B file processor Docker images"
  format        = "DOCKER"

  labels = {
    environment = var.environment
    project     = "b2b-processor"
  }
}

output "artifact_registry_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/b2b-processor"
  description = "Artifact Registry URL for Docker images"
}
