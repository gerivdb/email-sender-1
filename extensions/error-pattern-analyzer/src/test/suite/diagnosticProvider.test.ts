import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';
import { DiagnosticProvider } from '../../diagnosticProvider';

suite('DiagnosticProvider Test Suite', () => {
    let provider: DiagnosticProvider;
    let testDocument: vscode.TextDocument;

    suiteSetup(async () => {
        // Create an instance of the provider
        provider = new DiagnosticProvider(vscode.extensions.getExtension('augmentcode.error-pattern-analyzer')!.exports.getExtensionContext());

        // Open the test script
        const testScriptPath = path.join(__dirname, 'fixtures', 'test-script.ps1');
        testDocument = await vscode.workspace.openTextDocument(testScriptPath);
    });

    test('Should analyze PowerShell documents', async () => {
        // Call the analyze method
        provider.analyzeDocument(testDocument);

        // Wait for diagnostics to be published
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Get the diagnostics for the test document
        const diagnostics = vscode.languages.getDiagnostics(testDocument.uri);

        // Assert that diagnostics were created
        assert.ok(diagnostics.length > 0, 'No diagnostics were created');
    });

    test('Should not analyze non-PowerShell documents', async () => {
        // Create a non-PowerShell document
        const nonPsDocument = await vscode.workspace.openTextDocument({
            content: 'console.log("Hello, world!");',
            language: 'javascript'
        });

        // Call the analyze method
        provider.analyzeDocument(nonPsDocument);

        // Wait for diagnostics to be published
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Get the diagnostics for the non-PowerShell document
        const diagnostics = vscode.languages.getDiagnostics(nonPsDocument.uri);

        // Assert that no diagnostics were created
        assert.strictEqual(diagnostics.length, 0, 'Diagnostics were created for a non-PowerShell document');
    });

    test('Should respect configuration settings', async () => {
        // Get the current configuration
        const config = vscode.workspace.getConfiguration('errorPatternAnalyzer');
        const originalValue = config.get<boolean>('enableDiagnostics');

        try {
            // Disable diagnostics
            await config.update('enableDiagnostics', false, vscode.ConfigurationTarget.Global);

            // Call the analyze method
            provider.analyzeDocument(testDocument);

            // Wait for diagnostics to be published
            await new Promise(resolve => setTimeout(resolve, 1000));

            // Get the diagnostics for the test document
            const diagnostics = vscode.languages.getDiagnostics(testDocument.uri);

            // Assert that no diagnostics were created
            assert.strictEqual(diagnostics.length, 0, 'Diagnostics were created when disabled');

            // Enable diagnostics
            await config.update('enableDiagnostics', true, vscode.ConfigurationTarget.Global);

            // Call the analyze method
            provider.analyzeDocument(testDocument);

            // Wait for diagnostics to be published
            await new Promise(resolve => setTimeout(resolve, 1000));

            // Get the diagnostics for the test document
            const enabledDiagnostics = vscode.languages.getDiagnostics(testDocument.uri);

            // Assert that diagnostics were created
            assert.ok(enabledDiagnostics.length > 0, 'No diagnostics were created when enabled');
        } finally {
            // Restore the original configuration
            await config.update('enableDiagnostics', originalValue, vscode.ConfigurationTarget.Global);
        }
    });

    suiteTeardown(() => {
        // Dispose the provider
        provider.dispose();
    });
});
