import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';

suite('Extension Test Suite', () => {
    test('Extension should be present', () => {
        // Check if the extension is installed
        const extension = vscode.extensions.getExtension('augmentcode.error-pattern-analyzer');
        assert.ok(extension, 'Extension is not installed');
    });

    test('Extension should be activated', async () => {
        // Get the extension
        const extension = vscode.extensions.getExtension('augmentcode.error-pattern-analyzer');
        assert.ok(extension, 'Extension is not installed');
        
        // Activate the extension if it's not already activated
        if (!extension.isActive) {
            await extension.activate();
        }
        
        // Check if the extension is activated
        assert.ok(extension.isActive, 'Extension is not activated');
    });

    test('Extension should register commands', async () => {
        // Get all commands
        const commands = await vscode.commands.getCommands();
        
        // Check if the extension commands are registered
        assert.ok(commands.includes('error-pattern-analyzer.analyzeCurrentFile'), 'analyzeCurrentFile command is not registered');
        assert.ok(commands.includes('error-pattern-analyzer.showErrorPatterns'), 'showErrorPatterns command is not registered');
    });

    test('Extension should analyze PowerShell files', async () => {
        // Open the test script
        const testScriptPath = path.join(__dirname, 'fixtures', 'test-script.ps1');
        const document = await vscode.workspace.openTextDocument(testScriptPath);
        
        // Show the document in the editor
        await vscode.window.showTextDocument(document);
        
        // Execute the analyze command
        await vscode.commands.executeCommand('error-pattern-analyzer.analyzeCurrentFile');
        
        // Wait for diagnostics to be published
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Get the diagnostics for the test document
        const diagnostics = vscode.languages.getDiagnostics(document.uri);
        
        // Assert that diagnostics were created
        assert.ok(diagnostics.length > 0, 'No diagnostics were created');
    });
});
