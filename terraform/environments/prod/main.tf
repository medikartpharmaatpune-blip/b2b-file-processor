terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "project-97486c39-bcfe-41e5-9e8-tfstate"
    prefix = "environments/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_storage_project_service_account" "gcs_account" {}

module "storage" {
  source      = "../../modules/storage"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  force_destroy         = false
  input_retention_days  = 30
  output_retention_days = 90
}

module "pubsub" {
  source      = "../../modules/pubsub"
  project_id  = var.project_id
  environment = var.environment

  input_bucket_name         = module.storage.input_bucket_name
  gcs_service_account_email = data.google_storage_project_service_account.gcs_account.email_address

  ack_deadline_seconds  = 60
  max_delivery_attempts = 10
}

module "gke" {
  source      = "../../modules/gke"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  deletion_protection = true
}

module "iam" {
  source      = "../../modules/iam"
  project_id  = var.project_id
  environment = var.environment

  input_bucket_name        = module.storage.input_bucket_name
  output_bucket_name       = module.storage.output_bucket_name
  pubsub_subscription_name = module.pubsub.subscription_name
  pubsub_topic_name        = module.pubsub.topic_name
  gke_cluster_dependency   = module.gke.cluster_name
}

resource "google_artifact_registry_repository" "b2b_processor" {
  location      = var.region
  repository_id = "b2b-processor-prod"
  description   = "B2B file processor Docker images (prod)"
  format        = "DOCKER"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
