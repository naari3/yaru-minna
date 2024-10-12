locals {
  services = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "dns.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "sts.googleapis.com"
  ])
}

resource "google_project_service" "enable_api" {
  for_each                   = local.services
  project                    = local.project_id
  service                    = each.value
  disable_dependent_services = true
}
