resource "google_container_cluster" "primary" {
  name     = "b2b-cluster-${var.environment}"
  location = var.region          # regional, not zonal — required for Autopilot

  enable_autopilot = true

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  deletion_protection = false
}

# This must run AFTER the cluster exists — depends_on ensures ordering
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.b2b_processor.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/b2b-processor]"

  depends_on = [google_container_cluster.primary]
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}
