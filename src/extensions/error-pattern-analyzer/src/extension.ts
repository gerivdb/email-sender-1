// The module 'vscode' contains the VS Code extensibility API
import * as vscode from 'vscode';
import { DiagnosticProvider } from './diagnosticProvider';
import { ErrorPatternExplorer } from './errorPatternExplorer';
import { QuickFixProvider } from './quickFixProvider';

// Variable to store the extension context
let extensionContext: vscode.ExtensionContext;

// Function to get the extension context
export function getExtensionContext(): vscode.ExtensionContext {
    return extensionContext;
}

// This method is called when your extension is activated
export function activate(context: vscode.ExtensionContext): void {
    console.log('Activating Error Pattern Analyzer extension');

    // Store the extension context
    extensionContext = context;

    // Create instances of our providers
    const diagnosticProvider = new DiagnosticProvider(context);
    const errorPatternExplorer = new ErrorPatternExplorer(context);
    const quickFixProvider = new QuickFixProvider(context);

    // Register commands
    const analyzeCommand = vscode.commands.registerCommand('error-pattern-analyzer.analyzeCurrentFile', () => {
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const document = editor.document;
            if (document.languageId === 'powershell') {
                vscode.window.showInformationMessage('Fonctionnalité d\'analyse non disponible (ErrorPatternAnalyzer manquant)');
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

    const getEditorSelectionCommand = vscode.commands.registerCommand('error-pattern-analyzer.getEditorSelection', () => {
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const selection = editor.selection;
            const selectedText = editor.document.getText(selection);
            if (selectedText) {
                vscode.window.showInformationMessage('Texte sélectionné : ' + selectedText);
                // Ici, transmettre selectedText à l'agent ou à l'automatisation si besoin
            } else {
                vscode.window.showInformationMessage('Aucun texte sélectionné');
            }
        } else {
            vscode.window.showWarningMessage('Aucun éditeur actif');
        }
    });

    // Add commands to context
    context.subscriptions.push(analyzeCommand);
    context.subscriptions.push(showPatternsCommand);
    context.subscriptions.push(getEditorSelectionCommand);

    // Register providers
    context.subscriptions.push(diagnosticProvider);
    context.subscriptions.push(errorPatternExplorer);
    context.subscriptions.push(quickFixProvider);

    console.log('Error Pattern Analyzer extension activated');
}

// This method is called when your extension is deactivated
export function deactivate(): void {
    console.log('Error Pattern Analyzer extension deactivated');
}
