provider "google" {
  project = local.project_id
  region  = "us-central1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 5.10.0"
    }
  }
  required_version = ">= 1.6.0"
  backend "gcs" {
    bucket = "yaru-tfstate"
    prefix = "terraform/state"
  }
}
