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

resource "google_storage_bucket" "acmiyaguchi" {
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

resource "google_storage_bucket" "logs" {
  name     = "${local.project_id}-logs"
  location = "US"
}
