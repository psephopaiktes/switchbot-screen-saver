#!/usr/bin/env python3
"""Update the tap after publishing its verified archive; never downgrade it."""
import base64
import json
import os
import re
import subprocess
import sys
from pathlib import Path

candidate = Path(sys.argv[1]).read_bytes()
repo = os.environ['GH_REPO']
endpoint = f'repos/{repo}/contents/Casks/switchbot-screen-saver.rb'
response = subprocess.run(['gh', 'api', endpoint + '?ref=main'], capture_output=True)
if response.returncode == 0:
    current = json.loads(response.stdout)
    existing = base64.b64decode(current['content'])
elif b'HTTP 404' in response.stderr:
    current, existing = None, None  # Bootstrap the tap only after its first archive is published.
else:
    raise SystemExit('Cannot read the current cask; GitHub access failed')

def version(data):
    match = re.search(rb'^  version "(\d+\.\d+\.\d+)"$', data, re.MULTILINE)
    if not match:
        raise SystemExit('Cask version is missing or invalid')
    return tuple(map(int, match[1].split(b'.')))

old, new = version(existing) if existing is not None else (0, 0, 0), version(candidate)
if old > new:
    print('A newer release is already in the tap; leaving it unchanged.')
    sys.exit(0)
if old == new:
    if existing != candidate:
        raise SystemExit('Refusing to change an already published cask version')
    print('The cask is already current.')
    sys.exit(0)
payload = {
    'message': f'brew: update switchbot-screen-saver to {".".join(map(str, new))}',
    'content': base64.b64encode(candidate).decode(),
    'branch': 'main',
}
if current is not None:
    payload['sha'] = current['sha']
subprocess.run(['gh', 'api', '--method', 'PUT', endpoint, '--input', '-',
                '--jq', '.commit.html_url'], input=json.dumps(payload).encode(), check=True)
