terraform {
  backend "gcs" {
    bucket = "acmiyaguchi-terraform"
    prefix = "acmiyaguchi"
  }
}

locals {
  project_id = "acmiyaguchi"
  region     = "us-central1"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

resource "google_storage_bucket" "default" {
  name                        = local.project_id
  location                    = "US"
  uniform_bucket_level_access = true
  cors {
    origin          = ["https://acmiyaguchi.me"]
    method          = ["GET"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = local.project_id
  }
}

resource "google_storage_bucket_iam_binding" "default-public" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

resource "google_storage_bucket" "logs" {
  name     = "${local.project_id}-logs"
  location = "US"
}


// An object that can be used counting page visits
resource "google_storage_bucket_object" "ping" {
  name          = "ping"
  content       = "pong"
  bucket        = google_storage_bucket.default.name
  cache_control = "no-cache"
}
