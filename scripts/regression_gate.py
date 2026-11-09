"""Local-only Lyva regression gate. No restore, installs, deployment or workflow edits."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(info|warning|error) - (.*) - (.+):\d+:\d+ - ([\w]+)$")

def diagnostics(output):
    result = []
    for line in output.splitlines():
        m = DIAGNOSTIC.match(line)
        if m:
            result.append(' | '.join([m[1], m[3].replace('\\', '/'), m[4], m[2]]))
    return result

def analyzer_result(output, code, baseline):
    actual = diagnostics(output)
    new = list((Counter(actual) - Counter(baseline)).elements())
    summary = re.search(r'(\d+) issues? found', output)
    complete = (summary is not None and int(summary[1]) == len(actual)) or 'No issues found!' in output
    passed = code in (0, 1) and complete and not new and not any(d.startswith('error |') for d in actual)
    return {'passed': passed, 'existing_findings': len(actual), 'new_diagnostics': new, 'completed': complete}

def test_result(output, code):
    events = []
    for line in output.splitlines():
        try:
            event = json.loads(line)
            if isinstance(event, dict): events.append(event)
        except ValueError:
            pass
    done = [e for e in events if e.get('type') == 'done']
    tests = [e for e in events if e.get('type') == 'testDone' and not e.get('hidden', False)]
    skipped = sum(bool(e.get('skipped')) for e in tests)
    failed = sum(e.get('result') != 'success' for e in tests)
    passed = code == 0 and bool(tests) and bool(done) and done[-1].get('success') is True and not skipped and not failed
    return {'passed': passed, 'tests': len(tests), 'skipped': skipped, 'failed': failed, 'completed': bool(done)}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--flutter', type=Path, required=True, help='Existing approved Flutter SDK directory')
    parser.add_argument('--output', type=Path, required=True, help='New scratch directory for logs and result.json')
    parser.add_argument('--backend', type=Path, help='Optional existing isolated backend candidate (mock tests only)')
    parser.add_argument('--android', action='store_true', help='Also build debug APK with existing Android tooling')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env['CI'] = 'true'
    # Caller must explicitly supply isolated directories; never silently use normal app data.
    for key in ('PUB_CACHE', 'APPDATA', 'TEMP', 'TMP'):
        if not env.get(key): parser.error(f'{key} must point to the isolated task environment')
    flutter = args.flutter.resolve() / 'bin' / ('flutter.bat' if os.name == 'nt' else 'flutter')
    report = {'scope': 'local regression only; not release or live integration approval',
              'started': datetime.now(timezone.utc).isoformat(), 'checks': {},
              'not_verified': ['real Firebase/RevenueCat identity and billing', 'deployed quota enforcement',
                               'real AI endpoints', 'personalized adaptation and rollback',
                               'iOS/device notifications', 'assistive technology and process death']}
    def run(name, command, cwd=ROOT, timeout=600):
        try:
            result = subprocess.run([str(c) for c in command], cwd=cwd, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=timeout, encoding='utf-8', errors='replace')
            text, code = result.stdout, result.returncode
        except (OSError, subprocess.TimeoutExpired) as exc:
            text, code = f'{type(exc).__name__}: local command failed or timed out', -1
        (output / f'{name}.log').write_text(text, encoding='utf-8')
        print(f'{name}: exit {code}', flush=True)
        return text, code
    manifest = json.loads((ROOT / 'scripts/regression_manifest.json').read_text())
    lock = digest(ROOT / 'pubspec.lock')
    try:
        missing = [name for name in manifest['required_test_files'] if not (ROOT / name).is_file()]
        report['checks']['coverage_inventory'] = {'passed': not missing, 'missing_files': missing}
        if missing: raise RuntimeError('Required regression files missing')
        text, code = run('gate-self-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_regression_gate.py'])
        report['checks']['gate_self_tests'] = {'passed': code == 0}
        if code != 0: raise RuntimeError('Regression gate self-tests failed')
        version, code = run('toolchain', [flutter, '--version', '--machine'])
        try: installed = json.loads(version)['frameworkVersion']
        except (ValueError, KeyError): installed = None
        pinned = (ROOT / '.flutter-version').read_text().strip()
        report['checks']['toolchain'] = {'passed': code == 0 and installed == pinned, 'expected': pinned, 'actual': installed}
        if not report['checks']['toolchain']['passed']: raise RuntimeError('Pinned SDK unavailable; no tools installed')
        text, code = run('flutter-tests', [flutter, 'test', '--no-pub', '--machine'])
        report['checks']['flutter_tests'] = test_result(text, code)
        report['checks']['flutter_tests']['passed'] &= report['checks']['flutter_tests']['tests'] >= manifest['minimum_flutter_tests']
        baseline = json.loads((ROOT / 'scripts/analyzer_baseline.json').read_text())['diagnostics']
        text, code = run('analyzer', [flutter, 'analyze', '--no-pub'])
        report['checks']['analyzer'] = analyzer_result(text, code, baseline)
        if args.backend:
            backend = args.backend.resolve()
            package = json.loads((backend / 'package.json').read_text())
            # Refuse an unexpected lifecycle script rather than execute a changed command.
            allowed = {'build': 'tsc', 'test': 'npm run build && node --test test/*.test.cjs'}
            if package.get('scripts') != allowed: raise RuntimeError('Backend scripts changed; inspect before running')
            if any(not (backend / name).is_file() for name in manifest['backend_test_files']):
                raise RuntimeError('Required backend mock tests missing')
            backend_lock = digest(backend / 'package-lock.json')
            npm = shutil.which('npm.cmd' if os.name == 'nt' else 'npm')
            if not npm: raise RuntimeError('Existing npm not found')
            text, code = run('backend-build', [npm, 'run', 'build', '--ignore-scripts'], cwd=backend)
            report['checks']['backend_build'] = {'passed': code == 0}
            if code != 0: raise RuntimeError('Backend compile failed')
            node = shutil.which('node')
            if not node: raise RuntimeError('Existing Node not found')
            version, code = run('backend-toolchain', [node, '--version'], cwd=backend)
            report['checks']['backend_toolchain'] = {'passed': code == 0 and version.strip().startswith('v24.')}
            if not report['checks']['backend_toolchain']['passed']: raise RuntimeError('Backend requires existing Node 24')
            text, code = run('backend-tests', [node, '--test', '--test-reporter=tap', *manifest['backend_test_files']], cwd=backend)
            count = re.search(r'# tests (\d+)', text)
            passed = code == 0 and count is not None and int(count[1]) >= manifest['minimum_backend_tests'] and '# fail 0' in text and '# skipped 0' in text
            report['checks']['backend_mock_tests'] = {'passed': passed, 'tests': int(count[1]) if count else None}
            report['checks']['backend_lock'] = {'passed': backend_lock == digest(backend / 'package-lock.json')}
        if args.android:
            env['ORG_GRADLE_PROJECT_android.builder.sdkDownload'] = 'false'
            text, code = run('android-debug', [flutter, 'build', 'apk', '--debug', '--no-pub'])
            report['checks']['android_debug'] = {'passed': code == 0, 'installed': False}
    except Exception as exc:
        report['failure'] = str(exc)
    finally:
        report['checks']['dependency_lock'] = {'passed': lock == digest(ROOT / 'pubspec.lock'), 'sha256': lock}
        report['passed'] = bool(report['checks']) and 'failure' not in report and all(c['passed'] for c in report['checks'].values())
        report['finished'] = datetime.now(timezone.utc).isoformat()
        (output / 'result.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1

if __name__ == '__main__':
    sys.exit(main())
