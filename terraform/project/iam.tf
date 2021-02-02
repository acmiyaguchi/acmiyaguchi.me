locals {
  app_engine_email = "${google_app_engine_application.app.app_id}@appspot.gserviceaccount.com"
  members = [
    "serviceAccount:${local.app_engine_email}",
  ]
}

resource "google_storage_bucket_iam_binding" "default-public" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

resource "google_storage_bucket_iam_member" "log_bucket_writer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.legacyBucketWriter"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_project_iam_binding" "run-invoker" {
  role    = "roles/run.invoker"
  members = local.members
}
