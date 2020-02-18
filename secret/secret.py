import re
import os

from flask import Flask, send_from_directory


app = Flask(__name__, static_url_path="")


def is_valid_secret(secret):
    return re.match(r"^[a-zA-Z0-9_-]*$", secret) is not None

# It's only a secret if only I know the keys.
secrets = set(filter(is_valid_secret, os.listdir("resources")))

print(secrets)

@app.route('/secret/<secret_id>/<resource_id>')
def secret(secret_id, resource_id):
    if secret_id in secrets:
        # TODO: sanitize strings
        path = os.path.join(secret_id, resource_id)
        return send_from_directory("resources", path)

@app.route('/')
def index():
    return send_from_directory("resources", "index.html")

