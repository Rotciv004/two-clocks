#!/usr/bin/env python3
"""Validate the extracted final ZIP and rebuild its report without original inputs."""
import ast
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/phase4'
validation = json.loads((OUT / 'archive_validation.json').read_text())
package = Path(validation['extracted_to'])
archive = Path(validation['zip'])

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if sha(archive) != validation['sha256']:
    raise RuntimeError('ZIP changed after extraction')
with zipfile.ZipFile(archive) as handle:
    if handle.testzip() is not None:
        raise RuntimeError('ZIP CRC failure')
entries = {}
for line in (package / 'MANIFEST.sha256').read_text().splitlines():
    digest, name = line.split('  ', 1)
    if not (package / name).resolve().is_relative_to(package.resolve()):
        raise RuntimeError('Manifest traversal')
    if sha(package / name) != digest:
        raise RuntimeError('Extracted file changed: ' + name)
    entries[name] = digest
files = {p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file()}
if files != set(entries) | {'MANIFEST.sha256'}:
    raise RuntimeError('Untracked extracted file')
for name in files:
    parts = Path(name).parts
    if any(p in {'config', '.git', '.report-venv', '__pycache__', 'references', 'exports', 'backups'} for p in parts):
        raise RuntimeError('Private/cache/administrative path packaged: ' + name)
    if name.endswith(('.cnf', '.pem', '.key', '.kdbx', '.sqlite')) or Path(name).name.startswith('06_advanced_'):
        raise RuntimeError('Forbidden credential or fictitious bonus file: ' + name)
manifest = json.loads((package / 'evidence/replay/manifest.json').read_text())
if manifest['status'] != 'PASS':
    raise RuntimeError('No successful package replay')
checked_runtime = []
for name, expected in manifest['files'].items():
    if name == 'README.md':
        continue  # Documentation was completed after the SQL replay.
    if sha(package / name) != expected:
        raise RuntimeError('Extracted runtime differs from replay: ' + name)
    checked_runtime.append(name)
for path in (package / 'scripts').glob('*.py'):
    ast.parse(path.read_text(), filename=str(path))
for path in (package / 'scripts').glob('*.sh'):
    subprocess.run(['bash', '-n', str(path)], check=True, cwd='/tmp')
rebuilt = OUT / 'extracted_report.pdf'
command = [sys.executable, str(package / 'scripts/build_report.py'),
           '--evidence-root', str(package / 'evidence/replay'),
           '--output', str(rebuilt), '--audit-dir', str(OUT / 'extracted_report_build')]
completed = subprocess.run(command, check=True, cwd='/tmp', text=True, capture_output=True)
if sha(rebuilt) != sha(package / 'report.pdf') or sha(rebuilt) != sha(ROOT / 'report.pdf'):
    raise RuntimeError('Offline extracted report build differs from final inspected PDF')
for name, digest in entries.items():
    if sha(package / name) != digest:
        raise RuntimeError('Validation modified extracted input: ' + name)
result = {
    'status': 'PASS', 'archive_sha256': sha(archive), 'file_count': len(files),
    'manifest_pass_after_build': True, 'no_credentials_or_caches': True,
    'runtime_files_identical_to_successful_replay': checked_runtime,
    'working_directory': '/tmp', 'extracted_package': str(package),
    'report_rebuilt_offline_from_extracted_inputs': True,
    'report_sha256': sha(rebuilt), 'identical_to_visually_checked_final': True,
    'build_command': command, 'build_stdout': completed.stdout,
    'database_replay_source': manifest['package_root'],
    'database_replay_not_repeated_after_doc_only_changes': True
}
(OUT / 'extracted_validation.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print('PASS extracted ZIP: manifest/runtime/dependencies; offline report rebuild byte-identical')
