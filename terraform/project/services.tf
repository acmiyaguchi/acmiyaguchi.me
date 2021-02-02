resource "google_project_service" "cloudfunctions" {
  project = local.project_id
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  project = local.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudscheduler" {
  project = local.project_id
  service = "cloudscheduler.googleapis.com"
}
