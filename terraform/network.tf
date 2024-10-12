resource "google_compute_address" "minecraft" {
  name   = "minecraft-ip"
  region = local.region
}

resource "google_compute_network" "minecraft" {
  name = "minecraft"
}

# Open the firewall for Minecraft traffic
resource "google_compute_firewall" "minecraft" {
  name    = "minecraft"
  network = google_compute_network.minecraft.name
  # Minecraft client port
  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }
  # ICMP (ping)
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["minecraft"]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh"
  network = google_compute_network.minecraft.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["106.72.217.225/32"]
  target_tags   = ["minecraft"]
}
