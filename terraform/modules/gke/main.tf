resource "google_container_cluster" "primary" {
  name     = "b2b-cluster-${var.environment}"
  location = var.region
  project  = var.project_id

  enable_autopilot = true

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  deletion_protection = var.deletion_protection
}
