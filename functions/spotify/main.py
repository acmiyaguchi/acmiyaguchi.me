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
    print(f"dumping item to {bucket}/{prefix}")
    gcs = storage.Client()
    bucket = gcs.bucket(bucket)
    blob = bucket.blob(prefix)
    # always serve compressed content
    # https://cloud.google.com/storage/docs/transcoding#decompressive_transcoding
    blob.upload_from_string(dumps(object).encode())


def scrape_and_load(playlist):
    name = META[playlist]
    print(f"getting tracks for {playlist}")
    data = get_tracks(playlist)
    data_flat = transform(data)

    ds = datetime.now().isoformat()[:10]
    bucket = "acmiyaguchi"
    prefix = f"v1/data/spotify/{name}"
    dump_to_gcs(
        bucket,
        f"{prefix}/{ds}.ndjson",
        data_flat,
        dumps=ndjson.dumps,
    )
    # also dump the most recent version, which will have to be deduplicated
    dump_to_gcs(
        bucket,
        f"{prefix}/latest.json",
        data_flat,
    )

    bq = bigquery.Client()
    load_job = bq.load_table_from_uri(
        f"gs://{bucket}/{prefix}/*.ndjson",
        f"{PROJECT_ID}.spotify.{name}",
        job_config=bigquery.LoadJobConfig(
            autodetect=True,
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            write_disposition=bigquery.job.WriteDisposition.WRITE_TRUNCATE,
        ),
    )
    print(f"running load job {load_job.job_id}")
    load_job.result()


def spotify_playlist(request):
    # monday is 0, saturday is 5
    dow = date.today().weekday()
    if dow == 1:
        playlist = DISCOVER_WEEKLY
    elif dow == 5:
        playlist = RELEASE_RADAR
    else:
        print(f"no playlists to scrape today {datetime.now.isoformat()}")

    scrape_and_load(playlist)


if __name__ == "__main__":
    # we're going to get extra items in the bucket when we manually run outside
    # of the intended schedule
    scrape_and_load(DISCOVER_WEEKLY)
    scrape_and_load(RELEASE_RADAR)