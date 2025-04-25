// The module 'vscode' contains the VS Code extensibility API
import * as vscode from 'vscode';
import { DiagnosticProvider } from './diagnosticProvider';
import { ErrorPatternExplorer } from './errorPatternExplorer';
import { ErrorPatternAnalyzer } from './errorPatternAnalyzer';
import { QuickFixProvider } from './quickFixProvider';

// Variable to store the extension context
let extensionContext: vscode.ExtensionContext;

// Function to get the extension context
export function getExtensionContext(): vscode.ExtensionContext {
    return extensionContext;
}

// This method is called when your extension is activated
export function activate(context: vscode.ExtensionContext) {
    console.log('Activating Error Pattern Analyzer extension');

    // Store the extension context
    extensionContext = context;

    // Create instances of our providers
    const diagnosticProvider = new DiagnosticProvider(context);
    const errorPatternExplorer = new ErrorPatternExplorer(context);
    const errorPatternAnalyzer = new ErrorPatternAnalyzer(context);
    const quickFixProvider = new QuickFixProvider(context);

    // Register commands
    const analyzeCommand = vscode.commands.registerCommand('error-pattern-analyzer.analyzeCurrentFile', () => {
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const document = editor.document;
            if (document.languageId === 'powershell') {
                errorPatternAnalyzer.analyzeDocument(document);
                vscode.window.showInformationMessage('Analyzed PowerShell file for error patterns');
            } else {
                vscode.window.showWarningMessage('Error Pattern Analyzer only works with PowerShell files');
            }
        } else {
            vscode.window.showWarningMessage('No active editor');
        }
    });

    const showPatternsCommand = vscode.commands.registerCommand('error-pattern-analyzer.showErrorPatterns', () => {
        errorPatternExplorer.showErrorPatterns();
    });

    // Add commands to context
    context.subscriptions.push(analyzeCommand);
    context.subscriptions.push(showPatternsCommand);

    // Register providers
    context.subscriptions.push(diagnosticProvider);
    context.subscriptions.push(errorPatternExplorer);
    context.subscriptions.push(errorPatternAnalyzer);
    context.subscriptions.push(quickFixProvider);

    console.log('Error Pattern Analyzer extension activated');
}

// This method is called when your extension is deactivated
export function deactivate() {
    console.log('Error Pattern Analyzer extension deactivated');
}
