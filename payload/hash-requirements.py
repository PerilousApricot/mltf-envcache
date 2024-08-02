#!/usr/bin/env python3

#
# The report.json says what would be installed, this takes a hash of that in a
# hopefully stable way
#

import json
import hashlib
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <json report>", file=sys.stderr)
    print("Parses a json from pip3 install --dry-run --ignore-installed --report report.json -r test-requirements.txt and takes a hash", file=sys.stderr)
    sys.exit(1)

report = json.loads(open(sys.argv[1]).read())

packages = []
m = hashlib.sha256()

for i in report['install']:
    extras = ",".join(sorted(i['requested_extras'])) if 'requested_extras' in i else ''
    packages.append([i['metadata']['name'],
                     i['metadata']['version'],
                     extras,
                     i['download_info']['archive_info']['hash']])

packages_sorted = sorted(packages, key=lambda i: i[0])

# Generate a hash of the package contents
for p in packages_sorted:
    m.update(bytes("|".join(p), "utf-8"))

print(m.hexdigest())
