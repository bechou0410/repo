#!/usr/bin/env python3
"""Builds the APT index for repo.bechou.dev from the packages in pool/.

Writes Packages (plain, .gz, .bz2, .xz) and Release at the repository root. Each package's stanza is its
control file as built, plus Filename, Size and digests, plus the fields in tools/packages-extra.json for
that package (Sileo's depiction and icon). Run it after adding or removing a .deb: python3 tools/build-index.py
"""
import bz2, gzip, hashlib, json, lzma, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / 'pool'
EXTRA = json.loads((ROOT / 'tools/packages-extra.json').read_text())
RELEASE = {
    'Origin': 'bechou',
    'Label': 'bechou',
    'Suite': 'stable',
    'Version': '1.0',
    'Codename': 'ios',
    'Architectures': 'iphoneos-arm64',
    'Components': 'main',
    'Description': 'Tweak của bechou cho iPhone đã jailbreak (rootless).',
}


def control(deb):
    text = subprocess.run(['dpkg-deb', '-f', str(deb)], capture_output=True, text=True, check=True).stdout
    fields, last = [], None
    for line in text.splitlines():
        if line.startswith((' ', '\t')) and last is not None:
            fields[-1] = (fields[-1][0], fields[-1][1] + '\n' + line)
        elif ':' in line:
            key, value = line.split(':', 1)
            fields.append((key, value.strip()))
            last = key
    return fields


def stanza(deb):
    data = deb.read_bytes()
    fields = control(deb)
    package = dict(fields)['Package']
    known = {key for key, _ in fields}
    extra = [(key, value) for key, value in EXTRA.get(package, {}).items() if key not in known]
    fields += extra + [
        ('Filename', 'pool/' + deb.name),
        ('Size', str(len(data))),
        ('MD5sum', hashlib.md5(data).hexdigest()),
        ('SHA1', hashlib.sha1(data).hexdigest()),
        ('SHA256', hashlib.sha256(data).hexdigest()),
    ]
    return '\n'.join(f'{key}: {value}' for key, value in fields)


def main():
    debs = sorted(POOL.glob('*.deb'))
    if not debs:
        sys.exit('No packages in pool/.')
    packages = ('\n\n'.join(stanza(deb) for deb in debs) + '\n').encode()
    files = {
        'Packages': packages,
        'Packages.gz': gzip.compress(packages, mtime=0),
        'Packages.bz2': bz2.compress(packages),
        'Packages.xz': lzma.compress(packages),
    }
    for name, data in files.items():
        (ROOT / name).write_bytes(data)
    release = [f'{key}: {value}' for key, value in RELEASE.items()]
    for title, digest in (('MD5Sum', hashlib.md5), ('SHA1', hashlib.sha1), ('SHA256', hashlib.sha256)):
        release.append(title + ':')
        release += [f' {digest(data).hexdigest()} {len(data)} {name}' for name, data in files.items()]
    (ROOT / 'Release').write_text('\n'.join(release) + '\n')
    print(f'{len(debs)} package(s): ' + ', '.join(deb.name for deb in debs))


if __name__ == '__main__':
    main()
