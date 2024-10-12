resource "google_service_account" "yaru" {
  account_id   = "yaru-438413"
  display_name = "yaru"
}

resource "google_project_iam_member" "instance_admin" {
  project = local.project_id
  role    = "roles/compute.instanceAdmin"
  member  = google_service_account.yaru.member
}

resource "google_project_iam_member" "service_account_user" {
  project = local.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = google_service_account.yaru.member
}
