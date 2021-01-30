resource "google_bigquery_table" "default" {
  dataset_id = var.dataset_id
  table_id   = var.table_id
  view {
    use_legacy_sql = false
    query          = file("../../sql/${var.dataset_id}/${var.table_id}/view.sql")
  }
}
