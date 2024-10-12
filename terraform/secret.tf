resource "google_secret_manager_secret" "yaru_discord_bot_token" {
  secret_id = "yaru-discord-bot-token"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "yaru_discord_bot_token_accessor" {
  secret_id = google_secret_manager_secret.yaru_discord_bot_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.yaru.member
}
