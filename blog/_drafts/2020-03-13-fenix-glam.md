```
graph LR

subgraph Ingestion Ping Tables
    tables[org_mozilla_fenix_stable.*]
end

tables --> fenix_clients_daily_scalar_aggregates_bookmarks_sync
tables -->  fenix_clients_daily_scalar_aggregates_migration
tables --> fenix_clients_daily_scalar_aggregates_logins_sync
tables --> fenix_clients_daily_scalar_aggregates_metrics
tables --> fenix_clients_daily_scalar_aggregates_deletion_request
tables --> fenix_clients_daily_scalar_aggregates_events
tables --> fenix_clients_daily_scalar_aggregates_history_sync
tables --> fenix_clients_daily_scalar_aggregates_installation
tables --> fenix_clients_daily_scalar_aggregates_activation
tables --> fenix_clients_daily_scalar_aggregates_baseline
tables --> fenix_clients_daily_histogram_aggregates_metrics

subgraph Flatten and Aggregate
    fenix_clients_daily_scalar_aggregates_bookmarks_sync --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_migration --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_logins_sync --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_metrics --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_deletion_request --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_events --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_history_sync --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_installation --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_activation --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_scalar_aggregates_baseline --> fenix_view_clients_daily_scalar_aggregates
    fenix_clients_daily_histogram_aggregates_metrics --> fenix_view_clients_daily_histogram_aggregates
end
```

```
graph TD

subgraph Ingestion Ping Tables
    tables[org_mozilla_fenix_stable.*]
end

subgraph Flatten and Aggregate
tables --> fenix_view_clients_daily_scalar_aggregates
tables --> fenix_latest_versions
tables --> fenix_view_clients_daily_histogram_aggregates
end

subgraph Acccumulate
fenix_latest_versions --> fenix_clients_scalar_aggregates
fenix_latest_versions --> fenix_clients_histogram_aggregates
end

subgraph Transform for Visualization
fenix_view_clients_daily_scalar_aggregates --> fenix_clients_scalar_aggregates
fenix_view_clients_daily_histogram_aggregates --> fenix_clients_histogram_aggregates

fenix_clients_scalar_aggregates --> fenix_scalar_percentiles
fenix_clients_scalar_aggregates --> fenix_clients_scalar_bucket_counts
fenix_clients_scalar_bucket_counts --> fenix_clients_scalar_probe_counts

fenix_clients_histogram_aggregates --> fenix_clients_histogram_bucket_counts
fenix_clients_histogram_bucket_counts --> fenix_clients_histogram_probe_counts
fenix_clients_histogram_probe_counts --> fenix_histogram_percentiles
end

fenix_scalar_percentiles --> fenix_client_probe_counts
fenix_histogram_percentiles --> fenix_client_probe_counts
fenix_clients_scalar_probe_counts --> fenix_client_probe_counts
fenix_clients_histogram_probe_counts --> fenix_client_probe_counts
```
