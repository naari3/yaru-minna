resource "google_compute_disk" "world_data" {
  name = "world-data"
  type = "pd-standard"
  zone = local.zone
  size = 25
}
