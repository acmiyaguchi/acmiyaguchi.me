from subprocess import run
from pathlib import Path
from shutil import copyfile
import json

output = Path(__file__).parent.parent / "data/acmiyaguchi/midi"
assert output.is_dir()

for source in (Path.home() / "lmms/projects").glob("*.mid"):
    dest = output / source.name
    if dest.exists():
        print(f"skipping {source.name}")
        continue
    print(f"copying {source} into {dest}")
    copyfile(source, dest)

manifest = [dict(name=p.name) for p in sorted(output.glob("*"))]
(output / "manifest.json").write_text(json.dumps(manifest, indent=2))

run("gsutil -m rsync -r data/acmiyaguchi/ gs://acmiyaguchi".split(), shell=True)
