import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { ErrorPatternAnalyzer } from '../../errorPatternAnalyzer';

suite('ErrorPatternAnalyzer Test Suite', () => {
    let analyzer: ErrorPatternAnalyzer;
    let testDocument: vscode.TextDocument;

    suiteSetup(async () => {
        // Create an instance of the analyzer
        analyzer = new ErrorPatternAnalyzer(vscode.extensions.getExtension('augmentcode.error-pattern-analyzer')!.exports.getExtensionContext());

        // Open the test script
        const testScriptPath = path.join(__dirname, 'fixtures', 'test-script.ps1');
        testDocument = await vscode.workspace.openTextDocument(testScriptPath);
    });

    test('Should detect null reference errors', async () => {
        const patterns = analyzer.analyzeDocument(testDocument);

        // Find null reference patterns
        const nullReferencePatterns = patterns.filter(p => p.id === 'null-reference');

        // Assert that at least one null reference pattern was found
        assert.ok(nullReferencePatterns.length > 0, 'No null reference patterns found');

        // Assert that the pattern has the correct properties
        const pattern = nullReferencePatterns[0];
        assert.strictEqual(pattern.severity, 'warning');
        assert.ok(pattern.message.includes('null reference'), 'Message does not mention null reference');
    });

    test('Should detect index out of bounds errors', async () => {
        const patterns = analyzer.analyzeDocument(testDocument);

        // Find index out of bounds patterns
        const indexOutOfBoundsPatterns = patterns.filter(p => p.id === 'index-out-of-bounds');

        // Assert that at least one index out of bounds pattern was found
        assert.ok(indexOutOfBoundsPatterns.length > 0, 'No index out of bounds patterns found');

        // Assert that the pattern has the correct properties
        const pattern = indexOutOfBoundsPatterns[0];
        assert.strictEqual(pattern.severity, 'warning');
        assert.ok(pattern.message.includes('array index'), 'Message does not mention array index');
    });

    test('Should detect type conversion errors', async () => {
        const patterns = analyzer.analyzeDocument(testDocument);

        // Find type conversion patterns
        const typeConversionPatterns = patterns.filter(p => p.id === 'type-conversion');

        // Assert that at least one type conversion pattern was found
        assert.ok(typeConversionPatterns.length > 0, 'No type conversion patterns found');

        // Assert that the pattern has the correct properties
        const pattern = typeConversionPatterns[0];
        assert.strictEqual(pattern.severity, 'warning');
        assert.ok(pattern.message.includes('type conversion'), 'Message does not mention type conversion');
    });

    test('Should provide suggestions for detected errors', async () => {
        const patterns = analyzer.analyzeDocument(testDocument);

        // Assert that all patterns have suggestions
        for (const pattern of patterns) {
            assert.ok(pattern.suggestion, `Pattern ${pattern.id} does not have a suggestion`);
            assert.ok(pattern.codeExample, `Pattern ${pattern.id} does not have a code example`);
        }
    });
});
