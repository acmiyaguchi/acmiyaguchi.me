from subprocess import run

run(
    "gsutil -m rsync -r data/acmiyaguchi/ gs://acmiyaguchi/".split(),
    shell=True,
)