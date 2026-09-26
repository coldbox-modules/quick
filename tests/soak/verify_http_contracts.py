#!/usr/bin/env python3
"""Prove real k6 exits fail on misleading HTTP responses, including HTTP-green 404s."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import threading

HERE = Path(__file__).resolve().parent
CASES = {
    'missing_correct': (404, {'error': {'code': 'EntityNotFound', 'type': 'EntityNotFound'}}, True),
    'missing_wrong_code': (404, {'error': {'code': 'OtherFailure', 'type': 'EntityNotFound'}}, False),
    'missing_unrelated_exception': (404, {'error': {'code': 'EntityNotFound', 'type': 'DatabaseException'}}, False),
    'missing_unexpected_success': (200, {'data': {'id': 2000000000}}, False),
    'missing_unexpected_500': (500, {'error': {'code': 'EntityNotFound', 'type': 'EntityNotFound'}}, False),
    'missing_extra_data': (404, {'error': {'code': 'EntityNotFound', 'type': 'EntityNotFound'}, 'data': {'id': 1}}, False),
    'invalid_correct': (422, {'error': {'code': 'ValidationFailed', 'fields': {'title': 'required,maximum:80'}}}, True),
    'invalid_wrong_field': (422, {'error': {'code': 'ValidationFailed', 'fields': {'ownerToken': 'required'}}}, False),
}

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, body, _ = CASES[self.path.removeprefix('/')]
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def log_message(self, *args):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    server = ThreadingHTTPServer(('0.0.0.0', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    image = json.loads((HERE / 'profiles/lucee6-serial.json').read_text())['images']['k6']
    results = []
    try:
        for name, (status, _, should_pass) in CASES.items():
            with (args.output / (name + '.log')).open('w') as log:
                p = subprocess.run(['docker', 'run', '--rm', '--add-host', 'host.docker.internal:host-gateway',
                    '--user', '0', '-v', f'{HERE / "k6"}:/scripts:ro', '-v', f'{args.output.resolve()}:/proof',
                    '-e', f'PROBE_SUMMARY=/proof/{name}.json', '-e', f'CASE={name}', '-e',
                    f'PROBE_URL=http://host.docker.internal:{server.server_port}', image, 'run',
                    '--no-usage-report', '/scripts/contract-probe.mjs'], stdout=log, stderr=subprocess.STDOUT, timeout=60)
            # 99 specifically proves a k6 threshold failure rather than setup/script/network failure.
            metrics = json.loads((args.output / (name + '.json')).read_text())['metrics']
            expected_http_failure = status != (422 if name.startswith('invalid') else 404)
            http_failure = metrics['http_req_failed']['values']['rate']
            correct = metrics['checks']['values']['rate']
            results.append({'case': name, 'exitCode': p.returncode, 'expectedExitCode': 0 if should_pass else 99,
                            'httpFailureRate': http_failure, 'contractCheckRate': correct,
                            'passed': p.returncode == (0 if should_pass else 99) and correct == int(should_pass)
                            and http_failure == int(expected_http_failure)})
    finally:
        server.shutdown()
        server.server_close()
    report = {'passed': all(r['passed'] for r in results), 'cases': results}
    (args.output / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
