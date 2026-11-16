"""Verify isolated sandbox build flags without credentials or store access."""
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class IsolatedSandboxFlagsTest(unittest.TestCase):
    def flags(self, mode, branch='sandbox/ken-ios-2026-11-09', key='appl_fixture'):
        env = {k: v for k, v in os.environ.items() if not k.startswith(('LYVA_', 'CI_'))}
        env.update(LYVA_PRIVATE_SANDBOX_BUILD=mode, CI_BRANCH=branch,
                   LYVA_SANDBOX_IOS_PUBLIC_KEY=key)
        return subprocess.run(['bash', '-c',
            'set -euo pipefail; source ios/ci_scripts/sandbox_build_flags.sh; declare -p LYVA_BUILD_FLAGS'],
            cwd=ROOT, env=env, text=True, capture_output=True)

    def test_exact_isolated_policy_and_apple_only(self):
        r = self.flags('apple-isolated-billing')
        self.assertEqual(r.returncode, 0, r.stderr)
        for flag in ('LYVA_SANDBOX_TEST_BUILD=true', 'LYVA_ISOLATED_SANDBOX_IDENTITY=true',
                     'LYVA_GOOGLE_AUTH_REVIEWED=false',
                     'LYVA_BILLING_POLICY_REVISION=ios-single-tester-isolated-sandbox-v1'):
            self.assertIn(flag, r.stdout)
        self.assertNotIn('LYVA_BILLING_POLICY_REVISION=ios-single-tester-sandbox-v1', r.stdout)

    def test_normal_and_previous_modes_do_not_opt_in(self):
        for mode in ('', 'apple-identity', 'apple-billing'):
            r = self.flags(mode)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertNotIn('LYVA_ISOLATED_SANDBOX_IDENTITY=true', r.stdout)

    def test_unreviewed_branch_and_secret_key_rejected(self):
        for branch in ('main', 'integration/cross-platform-2026-11-09', ''):
            self.assertNotEqual(self.flags('apple-isolated-billing', branch).returncode, 0)
        self.assertNotEqual(self.flags('apple-isolated-billing', key='sk_invalid').returncode, 0)


if __name__ == '__main__':
    unittest.main()
