// scripts/audit.test.js
// Tests unitaires pour auditExistingScripts (Phase 2)

const { auditExistingScripts } = require('./audit');

test('auditExistingScripts finds files', () => {
  const result = auditExistingScripts('.');
  expect(result.filesFound.length).toBeGreaterThan(0);
});
