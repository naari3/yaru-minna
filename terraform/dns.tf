resource "google_dns_managed_zone" "yaru" {
  name     = "yaru-zone"
  dns_name = "yaru.naari3.net."
}

resource "google_dns_record_set" "a" {
  name         = "yaru.naari3.net."
  type         = "A"
  ttl          = 5
  managed_zone = google_dns_managed_zone.yaru.name
  rrdatas      = [google_compute_address.minecraft.address]
}
