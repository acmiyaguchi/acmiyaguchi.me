terraform {
  backend "gcs" {
    bucket = "acmiyaguchi-terraform"
    prefix = "acmiyaguchi"
  }
}

locals {
  project_id        = "acmiyaguchi"
  region            = "us-central1"
  app_engine_region = "us-west2"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

resource "google_app_engine_application" "app" {
  project     = local.project_id
  location_id = local.app_engine_region
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

// An object that can be used counting page visits
resource "google_storage_bucket_object" "ping" {
  name          = "ping"
  content       = "pong"
  bucket        = google_storage_bucket.default.name
  cache_control = "no-cache, no-store, must-revalidate"
}


resource "google_storage_bucket" "logs" {
  name     = "${local.project_id}-logs"
  location = "US"
}

resource "google_bigquery_dataset" "logs" {
  dataset_id = "logs"
  location   = "US"
  project    = local.project_id
}

resource "google_bigquery_dataset" "spotify" {
  dataset_id = "spotify"
  location   = "US"
  project    = local.project_id
}

module "view_logs_visitor_pings" {
  source     = "../modules/views"
  dataset_id = google_bigquery_dataset.logs.dataset_id
  table_id   = "visitor_pings"
}

module "view_logs_page_visits" {
  for_each = toset([
    "page_visits_daily", "page_visits_routes_all", "page_visits_routes_daily"
  ])
  source     = "../modules/views"
  dataset_id = google_bigquery_dataset.logs.dataset_id
  table_id   = each.value
  depends_on = [module.view_logs_visitor_pings]
}

module "function_usage_logs" {
  source                = "../modules/functions"
  name                  = "usage_logs"
  entry_point           = "usage_logs"
  service_account_email = local.app_engine_email
  bucket                = google_storage_bucket.default.name
  schedule              = "0 */6 * * *"
  timeout               = 120
  app_engine_region     = local.app_engine_region
}

module "function_sundew_crop_norm" {
  source                = "../modules/functions"
  name                  = "sundew-crop-norm"
  entry_point           = "main"
  service_account_email = local.app_engine_email
  bucket                = google_storage_bucket.default.name
  schedule              = null
  available_memory_mb   = 1024
  timeout               = 120
  app_engine_region     = local.app_engine_region
  public                = true
}

module "function_spotify" {
  source                = "../modules/functions"
  name                  = "spotify"
  entry_point           = "spotify_playlist"
  service_account_email = local.app_engine_email
  bucket                = google_storage_bucket.default.name
  schedule              = "0 0 * * 2,6"
  timeout               = 120
  app_engine_region     = local.app_engine_region
}

resource "google_secret_manager_secret" "spotify_client_id" {
  secret_id = "spotify-client-id"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret" "spotify_client_secret" {
  secret_id = "spotify-client-secret"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}
