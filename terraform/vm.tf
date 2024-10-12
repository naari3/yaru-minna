locals {
  machine_type = "t2a-standard-2"
}

resource "google_compute_instance_template" "minecraft_template" {
  name_prefix  = "minecraft-template-"
  machine_type = local.machine_type
  region       = local.region

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts-arm64"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
  }

  network_interface {
    network = google_compute_network.minecraft.name
    access_config {
      nat_ip = google_compute_address.minecraft.address
    }
  }

  service_account {
    email  = google_service_account.yaru.email
    scopes = ["userinfo-email", "https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  metadata_startup_script = <<EOF
INSTANCE_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google" | tr -d '\n')

# 新しいディスクを確認し、存在する場合はフォーマットしてマウントする!!!
FS_TYPE="ext4"
DISK="/dev/disk/by-id/google-minecraft"
MOUNT_POINT="/mnt/stateful_partition/minecraft"

gcloud compute instances attach-disk $INSTANCE_NAME \
  --disk ${google_compute_disk.world_data.name} \
  --zone ${local.zone} \
  --device-name minecraft \
  --mode rw

# デバイスが現れるまで待つ
while [ ! -e $DISK ]; do
  echo "Waiting for $DEVICE to be attached"
  sleep 1
done

# マウントポイントを作成
mkdir -p "$${MOUNT_POINT}"

# ディスクがフォーマットされているか確認
if ! blkid "$${DISK}" > /dev/null 2>&1; then
    echo "Formatting disk $${DISK}"
    # ディスクをフォーマット
    mkfs.ext4 -F "$${DISK}"
fi

# ディスクをマウント
echo "Mounting disk $${DISK} at $${MOUNT_POINT}"
mount -t "$${FS_TYPE}" "$${DISK}" "$${MOUNT_POINT}"

# 自動マウントの設定
if ! grep -qs "$${MOUNT_POINT} " /etc/fstab; then
    echo "Adding $${MOUNT_POINT} to /etc/fstab"
    echo "$${DISK} $${MOUNT_POINT} $${FS_TYPE} defaults 0 2" >> /etc/fstab
fi

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable"
apt-get install -y docker-ce
apt-get install docker-compose-plugin
systemctl start docker
systemctl enable docker

git clone https://github.com/naari3/yaru-minna ~/yaru-minna
cd ~/yaru-minna/docker
DISCORD_BOT_TOKEN=$(gcloud secrets versions access latest --secret="yaru-discord-bot-token")
cp docker-compose.override.example.yaml docker-compose.override.yaml
sed -i "s/your_token/$${DISCORD_BOT_TOKEN}/g" ~/yaru-minna/docker/docker-compose.override.yaml
docker compose up -d
EOF

  metadata = {
    enable-oslogin  = "TRUE"
    shutdown-script = <<EOF
#!/bin/bash
cd ~/yaru-minna/docker && docker compose exec mc rcon-cli say 王道注意
cd ~/yaru-minna/docker && docker compose exec mc rcon-cli save-all
EOF
  }

  tags = ["minecraft"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "minecraft_group" {
  name               = "minecraft-group"
  base_instance_name = "minecraft"
  version {
    instance_template = google_compute_instance_template.minecraft_template.self_link
  }
  zone        = local.zone
  target_size = 1
}
