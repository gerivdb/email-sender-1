import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';
import { QuickFixProvider } from '../../quickFixProvider';
import { DiagnosticProvider } from '../../diagnosticProvider';

suite('QuickFixProvider Test Suite', () => {
    let quickFixProvider: QuickFixProvider;
    let diagnosticProvider: DiagnosticProvider;
    let testDocument: vscode.TextDocument;

    suiteSetup(async () => {
        const context = vscode.extensions.getExtension('augmentcode.error-pattern-analyzer')!.exports.getExtensionContext();

        // Create instances of the providers
        quickFixProvider = new QuickFixProvider(context);
        diagnosticProvider = new DiagnosticProvider(context);

        // Open the test script
        const testScriptPath = path.join(__dirname, 'fixtures', 'test-script.ps1');
        testDocument = await vscode.workspace.openTextDocument(testScriptPath);

        // Analyze the document to generate diagnostics
        diagnosticProvider.analyzeDocument(testDocument);

        // Wait for diagnostics to be published
        await new Promise(resolve => setTimeout(resolve, 1000));
    });

    test('Should provide code actions for diagnostics', async () => {
        // Get the diagnostics for the test document
        const diagnostics = vscode.languages.getDiagnostics(testDocument.uri);

        // Assert that diagnostics were created
        assert.ok(diagnostics.length > 0, 'No diagnostics were created');

        // For each diagnostic, check if code actions are provided
        for (const diagnostic of diagnostics) {
            // Create a range for the diagnostic
            const range = diagnostic.range;

            // Get code actions for the diagnostic
            const codeActions = await vscode.commands.executeCommand<vscode.CodeAction[]>(
                'vscode.executeCodeActionProvider',
                testDocument.uri,
                range,
                vscode.CodeActionKind.QuickFix.value
            );

            // Assert that code actions were provided
            assert.ok(codeActions && codeActions.length > 0, `No code actions were provided for diagnostic: ${diagnostic.message}`);

            // Assert that the code actions have the correct properties
            for (const action of codeActions) {
                assert.ok(action.title, 'Code action does not have a title');
                assert.ok(action.kind && action.kind.contains(vscode.CodeActionKind.QuickFix), 'Code action is not a quick fix');
                assert.ok(action.edit || action.command, 'Code action does not have an edit or command');
            }
        }
    });

    test('Should provide null check code actions', async () => {
        // Get the diagnostics for the test document
        const diagnostics = vscode.languages.getDiagnostics(testDocument.uri);

        // Find a null reference diagnostic
        const nullReferenceDiagnostic = diagnostics.find(d => d.code === 'null-reference');

        if (nullReferenceDiagnostic) {
            // Create a range for the diagnostic
            const range = nullReferenceDiagnostic.range;

            // Get code actions for the diagnostic
            const codeActions = await vscode.commands.executeCommand<vscode.CodeAction[]>(
                'vscode.executeCodeActionProvider',
                testDocument.uri,
                range,
                vscode.CodeActionKind.QuickFix.value
            );

            // Assert that code actions were provided
            assert.ok(codeActions && codeActions.length > 0, 'No code actions were provided for null reference diagnostic');

            // Find a null check code action
            const nullCheckAction = codeActions.find(a => a.title.includes('null check'));

            // Assert that a null check code action was provided
            assert.ok(nullCheckAction, 'No null check code action was provided');

            // Assert that the code action has an edit
            assert.ok(nullCheckAction.edit, 'Null check code action does not have an edit');
        } else {
            assert.fail('No null reference diagnostic was found');
        }
    });

    suiteTeardown(() => {
        // Dispose the providers
        quickFixProvider.dispose();
        diagnosticProvider.dispose();
    });
});
