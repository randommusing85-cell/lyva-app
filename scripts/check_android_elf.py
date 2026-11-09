"""Read-only APK ELF LOAD alignment check; does not establish runtime compatibility."""
import argparse
import json
from pathlib import Path
import struct
import sys
import zipfile

def load_alignments(data):
    if len(data) < 64 or data[:5] != b'\x7fELF\x02' or data[5] not in (1, 2):
        raise ValueError('Expected a valid 64-bit ELF header')
    endian = '<' if data[5] == 1 else '>'
    offset = struct.unpack_from(endian + 'Q', data, 32)[0]
    size, count = struct.unpack_from(endian + 'HH', data, 54)
    if size < 56 or count == 0 or offset + size * count > len(data):
        raise ValueError('Invalid program header table')
    result = []
    for i in range(count):
        segment = struct.unpack_from(endian + 'IIQQQQQQ', data, offset + size * i)
        if segment[0] == 1:
            result.append({'alignment': segment[7], 'congruent_16k': segment[2] % 16384 == segment[3] % 16384})
    if not result: raise ValueError('No LOAD segments')
    return result

def inspect(apk):
    rows = []
    with zipfile.ZipFile(apk) as archive:
        for name in sorted(archive.namelist()):
            if name.startswith(('lib/arm64-v8a/', 'lib/x86_64/')) and name.endswith('.so'):
                try:
                    loads = load_alignments(archive.read(name))
                    rows.append({'library': name, 'loads': loads,
                                 'passed': all(s['alignment'] >= 16384 and s['congruent_16k'] for s in loads)})
                except (ValueError, struct.error) as exc:
                    rows.append({'library': name, 'passed': False, 'error': str(exc)})
    return {'scope': '64-bit ELF LOAD alignment only; ZIP/RELRO and device tests are separate',
            'passed': bool(rows) and all(r['passed'] for r in rows), 'libraries': rows}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    args = parser.parse_args()
    result = inspect(args.apk)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result['passed'] else 1)
