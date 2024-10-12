locals {
  github_repository            = "naari3/yaru-server"
  project_id                   = "yaru-438413"
  region                       = "us-central1"
  terraform_service_account_id = "tf-exec"
  terraform_service_account    = "${local.terraform_service_account_id}@${local.project_id}.iam.gserviceaccount.com"
  github_repo_owner            = "naari3"

  services = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ])
}

provider "google" {
  project     = local.project_id
  region      = "us-central1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 5.10.0"
    }
  }
  backend "gcs" {
    bucket = "yaru-tfstate"
    prefix = "bootstrap-terraform/state"
  }
}

resource "google_project_service" "enable_api" {
  for_each                   = local.services
  project                    = local.project_id
  service                    = each.value
  disable_dependent_services = true
}

resource "google_iam_workload_identity_pool" "yaru_pool" {
  project                   = local.project_id
  workload_identity_pool_id = "yaru-pool"
  display_name              = "yaru-pool"
  description               = "GitHub Actions で使用"
}

resource "google_iam_workload_identity_pool_provider" "yaru_prdr" {
  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.yaru_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "yaru-prdr"
  display_name                       = "yaru-prdr"
  description                        = "GitHub Actions で使用"
  attribute_condition                = "assertion.repository_owner == \"${local.github_repo_owner}\""

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "terraform_sa" {
  account_id   = local.terraform_service_account_id
  display_name = "terraform_sa"
}

resource "google_project_iam_member" "terraform_sa_owner" {
  project = local.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_service_account_iam_member" "terraform_sa" {
  service_account_id = google_service_account.terraform_sa.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.yaru_pool.name}/attribute.repository/${local.github_repository}"
}
