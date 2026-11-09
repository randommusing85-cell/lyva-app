import json
import unittest
from regression_gate import analyzer_result, diagnostics, test_result

LINE = "   info - Existing issue - lib/example.dart:2:3 - sample_lint"
class GateTests(unittest.TestCase):
    def test_existing_debt_is_explicit(self):
        result = analyzer_result(LINE + "\n1 issue found", 1, diagnostics(LINE))
        self.assertTrue(result['passed']); self.assertEqual(result['existing_findings'], 1)
    def test_new_occurrence_of_same_warning_fails(self):
        self.assertFalse(analyzer_result(LINE + "\n" + LINE.replace(':2:', ':4:') + "\n2 issues found", 1, diagnostics(LINE))['passed'])
    def test_incomplete_or_crashed_analyzer_fails(self):
        self.assertFalse(analyzer_result(LINE, 1, diagnostics(LINE))['passed'])
        self.assertFalse(analyzer_result('No issues found!', 2, [])['passed'])
    def test_line_movement_and_debt_removal_allowed(self):
        self.assertTrue(analyzer_result(LINE.replace(':2:3', ':200:9') + '\n1 issue found', 1, diagnostics(LINE))['passed'])
        self.assertTrue(analyzer_result('No issues found!', 0, diagnostics(LINE))['passed'])
    def test_errors_never_grandfathered(self):
        line = LINE.replace('info -', 'error -')
        self.assertFalse(analyzer_result(line + '\n1 issue found', 1, diagnostics(line))['passed'])
    def test_complete_tests_required(self):
        self.assertFalse(test_result('', 0)['passed'])
        self.assertFalse(test_result(json.dumps({'type':'done','success':True}), 0)['passed'])
    def test_success_skip_failure_and_missing_done(self):
        test = {'type':'testDone', 'result':'success', 'skipped':False, 'hidden':False}
        def output(t): return json.dumps(t) + '\n' + json.dumps({'type':'done','success':True})
        self.assertTrue(test_result(output(test), 0)['passed'])
        self.assertFalse(test_result(output(dict(test, skipped=True)), 0)['passed'])
        self.assertFalse(test_result(output(dict(test, result='failure')), 0)['passed'])
        self.assertFalse(test_result(output(test), 1)['passed'])
        self.assertFalse(test_result(json.dumps(test), 0)['passed'])

if __name__ == '__main__': unittest.main()
