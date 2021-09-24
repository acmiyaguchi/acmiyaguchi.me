# pinecube capture normalization

```bash
venv/Script/activate
gsutil -m rsync gs://acmiyaguchi/pinecube/captures_v2 data/captures_v2
python .\scripts\timelapse.py data/test.gif
```

## notes

- 2021-09-19 - in the afternoon pst, adjusted the camera to get the full frame
