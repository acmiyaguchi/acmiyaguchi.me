import hashlib
import json
import uuid
from datetime import date, datetime

import ndjson
import spotipy
from google.cloud import bigquery, secretmanager, storage
from spotipy.oauth2 import SpotifyClientCredentials

PROJECT_ID = "acmiyaguchi"

DISCOVER_WEEKLY = "spotify:playlist:37i9dQZEVXcElxG2oNKM3j"
RELEASE_RADAR = "spotify:playlist:37i9dQZEVXbpkMgUcfdHnz"
META = {
    # Updates Mondays
    DISCOVER_WEEKLY: "discover_weekly_v1",
    # Updates Fridays
    RELEASE_RADAR: "release_radar_v1",
}


def get_key(sm, key):
    response = sm.access_secret_version(
        request={"name": f"projects/{PROJECT_ID}/secrets/{key}/versions/latest"}
    )
    return response.payload.data.decode("utf-8")


def get_tracks(playlist):
    sm = secretmanager.SecretManagerServiceClient()
    client_id = get_key(sm, "spotify-client-id")
    client_secret = get_key(sm, "spotify-client-secret")
    spotify = spotipy.Spotify(
        client_credentials_manager=SpotifyClientCredentials(
            client_id=client_id, client_secret=client_secret
        )
    )
    return spotify.playlist_tracks(playlist)


def transform(data):
    rows = data["items"]
    track_ids = [row["track"]["id"] for row in rows]
    meta = dict(
        href=data["href"],
        timestamp=datetime.now().isoformat(),
        id=str(uuid.uuid4()),
        track_id_sha1=hashlib.sha1("".join(track_ids).encode()).hexdigest(),
    )
    return [dict(meta=meta, **row) for row in rows]


def dump_to_gcs(bucket, prefix, object, dumps=json.dumps):
    """Upload data to a gcs bucket in a compressed format."""
    gcs = storage.Client()
    bucket = gcs.bucket(bucket)
    blob = bucket.blob(prefix)
    # always serve compressed content
    # https://cloud.google.com/storage/docs/transcoding#decompressive_transcoding
    blob.upload_from_string(dumps(object).encode())


def spotify_discover(request):
    # TODO: conditional that runs a day of the week
    data = get_tracks(RELEASE_RADAR)
    data_flat = transform(data)

    # insert into bigquery
    name = META[RELEASE_RADAR]

    ds = datetime.now().isoformat()[:10]
    bucket = "acmiyaguchi"
    prefix = f"v1/data/spotify/{name}/{ds}.ndjson"
    dump_to_gcs(
        bucket,
        prefix,
        data_flat,
        dumps=ndjson.dumps,
    )

    bq = bigquery.Client()
    load_job = bq.load_table_from_uri(
        f"gs://{bucket}/{prefix.rstrip('.ndjson')}*",
        f"{PROJECT_ID}.spotify.{name}",
        job_config=bigquery.LoadJobConfig(
            autodetect=True,
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            write_disposition=bigquery.job.WriteDisposition.WRITE_TRUNCATE,
        ),
    )
    print(f"running load job {load_job.job_id}")
    load_job.result()


if __name__ == "__main__":
    spotify_discover(None)