#!/usr/bin/env python3
"""Validate a saver archive and generate its checksum-pinned Homebrew cask."""
import argparse
import hashlib
import plistlib
import re
import tarfile
from pathlib import Path, PurePosixPath

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--version', required=True)
parser.add_argument('--archive', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--repository', default='psephopaiktes/switchbot-screen-saver')
parser.add_argument('--url', help='Override the download URL for local CI installation checks')
args = parser.parse_args()
if not re.fullmatch(r'\d+\.\d+\.\d+', args.version):
    parser.error('Version must have the form X.Y.Z')
if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', args.repository):
    parser.error('Invalid repository')
with tarfile.open(args.archive, 'r:gz') as archive:
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        if path.is_absolute() or '..' in path.parts or path.parts[0] != 'SwitchBotScreenSaver.saver':
            raise SystemExit('Archive must contain only SwitchBotScreenSaver.saver')
        if not (member.isfile() or member.isdir()):
            raise SystemExit('Unexpected archive entry type')
        if member.isfile():
            archive.extractfile(member).read()  # Read every entry to check the compressed stream.
    prefix = 'SwitchBotScreenSaver.saver/Contents/'
    info = plistlib.load(archive.extractfile(prefix + 'Info.plist'))
    if info['CFBundleShortVersionString'] != args.version:
        raise SystemExit('Archive version does not match the release')
    for name in ['thumbnail.png', 'thumbnail@2x.png']:
        if archive.extractfile(prefix + 'Resources/' + name).read(8) != b'\x89PNG\r\n\x1a\n':
            raise SystemExit('Missing or invalid thumbnail')
checksum = hashlib.sha256(args.archive.read_bytes()).hexdigest()
url = args.url or f'https://github.com/{args.repository}/releases/download/v#{{version}}/SwitchBotScreenSaver-macos.tar.gz'
if any(char in url for char in ['"', '\\', '\n', '\r']):
    parser.error('Invalid download URL')
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(f'''cask "switchbot-screen-saver" do
  version "{args.version}"
  sha256 "{checksum}"

  url "{url}"
  name "SwitchBot Screen Saver"
  desc "Clock, date, and SwitchBot temperature and humidity screen saver"
  homepage "https://github.com/{args.repository}"

  depends_on macos: :ventura

  screen_saver "SwitchBotScreenSaver.saver"

  caveats <<~EOS
    Quit System Settings and the screen saver before upgrading.
    This screen saver is not notarized by Apple. If blocked, allow it in
    System Settings > Privacy & Security > Open Anyway, then reopen System Settings.
  EOS
end
''')
print(f'Validated {args.version}; generated {args.output} with SHA256 {checksum}')
