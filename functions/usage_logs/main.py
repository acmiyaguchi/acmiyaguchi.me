import gzip
import json
from datetime import date, datetime

from google.cloud import bigquery, storage


def default_serializer(obj):
    """JSON serializer for objects that cannot be serialized by default json code

    https://stackoverflow.com/a/22238613
    """
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} cannot be serialized")


def dump_to_gcs(bucket, name, query):
    """Upload data to a gcs bucket in a compressed format."""
    bq = bigquery.Client()
    gcs = storage.Client()
    bucket = gcs.bucket(bucket)
    blob = bucket.blob(
        f"v1/query/{name}.json",
    )
    blob.content_encoding = "gzip"
    # always serve compressed content
    blob.cache_control = "no-cache,no-transform"
    job = bq.query(query)
    print(f"running query {job.job_id} for {name}: {query}")
    output = [dict(row) for row in job]
    # https://cloud.google.com/storage/docs/transcoding#decompressive_transcoding
    blob.upload_from_string(
        gzip.compress(json.dumps(output, default=default_serializer).encode()),
        content_type="application/json",
    )


def usage_logs(request):
    bq = bigquery.Client()
    job_config = bigquery.LoadJobConfig(
        autodetect=True,
        source_format=bigquery.SourceFormat.CSV,
        # just always load the entire bucket into BigQuery
        write_disposition=bigquery.job.WriteDisposition.WRITE_TRUNCATE,
    )
    load_job = bq.load_table_from_uri(
        "gs://acmiyaguchi-logs/acmiyaguchi_usage*",
        "acmiyaguchi.logs.acmiyaguchi_usage",
        job_config=job_config,
    )
    print(f"running load job {load_job.job_id}")
    load_job.result()

    def query(dataset, table):
        dump_to_gcs(
            "acmiyaguchi", f"{dataset}_{table}", f"select * from {dataset}.{table}"
        )

    query("logs", "page_visits_daily")
    query("logs", "page_visits_routes_all")
    query("logs", "page_visits_routes_daily")

    return "OK"


if __name__ == "__main__":
    usage_logs(None)
