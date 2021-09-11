locals {
  tmp_zip = "/tmp/${var.name}.zip"
}

data "archive_file" "archive" {
  type        = "zip"
  source_dir  = "../../functions/${var.name}"
  output_path = local.tmp_zip
}

resource "google_storage_bucket_object" "archive" {
  name   = "functions/${var.name}-${data.archive_file.archive.output_sha}.zip"
  bucket = var.bucket
  source = local.tmp_zip
}

resource "google_cloudfunctions_function" "default" {
  name                  = var.name
  runtime               = "python38"
  available_memory_mb   = var.available_memory_mb
  source_archive_bucket = var.bucket
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point           = var.entry_point
  trigger_http          = true
  service_account_email = var.service_account_email
  timeout               = var.timeout
  labels = {
    "deployment-tool" = "cli-gcloud"
  }
  environment_variables = {
    BUCKET = var.bucket
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  count          = var.public ? 1 : 0
  cloud_function = google_cloudfunctions_function.default.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}


resource "google_cloud_scheduler_job" "default" {
  count       = var.schedule == null ? 0 : 1
  name        = var.entry_point
  region      = var.app_engine_region
  description = "schedule a cloud function for ${var.name}"
  schedule    = var.schedule
  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.default.https_trigger_url
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
}
