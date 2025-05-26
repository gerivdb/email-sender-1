import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';
import { DiagnosticProvider } from '../../diagnosticProvider';

suite('DiagnosticProvider Test Suite', () => {
    let provider: DiagnosticProvider;
    let testDocument: vscode.TextDocument;

    suiteSetup(async () => {
        // Get the extension
        const extension = vscode.extensions.getExtension('augmentcode.error-pattern-analyzer');
        if (!extension) {
            throw new Error('Extension is not installed');
        }

        // Create an instance of the provider
        provider = new DiagnosticProvider(extension.exports.getExtensionContext());

        // Open the test script
        const testScriptPath = path.join(__dirname, 'fixtures', 'test-script.ps1');
        testDocument = await vscode.workspace.openTextDocument(testScriptPath);
    });

    test('Should analyze PowerShell documents', async () => {
        // Prepare to listen for diagnostic changes
        const diagnosticsPromise = new Promise<vscode.Diagnostic[]>(resolve => {
            const disposable = vscode.languages.onDidChangeDiagnostics(e => {
                if (e.uris.some(uri => uri.toString() === testDocument.uri.toString())) {
                    const diagnostics = vscode.languages.getDiagnostics(testDocument.uri);
                    disposable.dispose();
                    resolve(diagnostics);
                }
            });
            // Call the analyze method after setting up the listener
            provider.analyzeDocument(testDocument);
        });

        // Wait for diagnostics with a reasonable timeout
        const diagnostics = await Promise.race([
            diagnosticsPromise,
            new Promise<vscode.Diagnostic[]>((_, reject) => 
                setTimeout(() => reject(new Error('Timeout waiting for diagnostics')), 500)
            )
        ]);

        // Assert that diagnostics were created
        assert.ok(diagnostics.length > 0, 'No diagnostics were created');
    });

    test('Should not analyze non-PowerShell documents', async () => {
        const nonPsDocument = await vscode.workspace.openTextDocument({
            content: 'console.log("Hello, world!");',
            language: 'javascript'
        });

        // Prepare to listen for diagnostic changes
        const diagnosticsPromise = new Promise<vscode.Diagnostic[]>(resolve => {
            const disposable = vscode.languages.onDidChangeDiagnostics(e => {
                if (e.uris.some(uri => uri.toString() === nonPsDocument.uri.toString())) {
                    const diagnostics = vscode.languages.getDiagnostics(nonPsDocument.uri);
                    disposable.dispose();
                    resolve(diagnostics);
                }
            });
            // Call the analyze method after setting up the listener
            provider.analyzeDocument(nonPsDocument);
        });

        // Wait for diagnostics with a shorter timeout
        const diagnostics = await Promise.race([
            diagnosticsPromise,
            new Promise<vscode.Diagnostic[]>(resolve => setTimeout(() => resolve([]), 300))
        ]);

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
