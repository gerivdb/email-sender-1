import * as vscode from 'vscode';
import { ErrorPatternAnalyzer } from './errorPatternAnalyzer';

/**
 * Provider for error pattern diagnostics in PowerShell files
 */
export class DiagnosticProvider implements vscode.Disposable {
    private diagnosticCollection: vscode.DiagnosticCollection;
    private analyzer: ErrorPatternAnalyzer;
    private disposables: vscode.Disposable[] = [];

    constructor(context: vscode.ExtensionContext) {
        this.diagnosticCollection = vscode.languages.createDiagnosticCollection('errorPatterns');
        this.analyzer = new ErrorPatternAnalyzer(context);

        // Register event handlers
        this.disposables.push(
            vscode.workspace.onDidOpenTextDocument(this.analyzeDocument, this),
            vscode.workspace.onDidChangeTextDocument(event => this.analyzeDocument(event.document), this),
            vscode.workspace.onDidCloseTextDocument(doc => {
                this.diagnosticCollection.delete(doc.uri);
            }, this)
        );

        // Analyze all open PowerShell documents
        vscode.workspace.textDocuments.forEach(this.analyzeDocument, this);
    }

    /**
     * Analyze a document for error patterns and update diagnostics
     */
    public analyzeDocument(document: vscode.TextDocument): void {
        // Only analyze PowerShell files
        if (document.languageId !== 'powershell') {
            return;
        }

        // Check if diagnostics are enabled
        const config = vscode.workspace.getConfiguration('errorPatternAnalyzer');
        if (!config.get<boolean>('enableDiagnostics', true)) {
            this.diagnosticCollection.delete(document.uri);
            return;
        }

        // Analyze the document
        const diagnostics: vscode.Diagnostic[] = [];
        const patterns = this.analyzer.analyzeDocument(document);

        // Create diagnostics for each pattern
        for (const pattern of patterns) {
            const range = new vscode.Range(
                new vscode.Position(pattern.lineNumber, pattern.startColumn),
                new vscode.Position(pattern.lineNumber, pattern.endColumn)
            );

            const diagnostic = new vscode.Diagnostic(
                range,
                pattern.message,
                this.getSeverity(pattern.severity)
            );

            diagnostic.code = pattern.id;
            diagnostic.source = 'Error Pattern Analyzer';
            diagnostic.relatedInformation = this.getRelatedInformation(pattern);

            diagnostics.push(diagnostic);
        }

        // Update diagnostics
        this.diagnosticCollection.set(document.uri, diagnostics);
    }

    /**
     * Convert pattern severity to VS Code diagnostic severity
     */
    private getSeverity(severity: string): vscode.DiagnosticSeverity {
        switch (severity) {
            case 'error':
                return vscode.DiagnosticSeverity.Error;
            case 'warning':
                return vscode.DiagnosticSeverity.Warning;
            case 'information':
                return vscode.DiagnosticSeverity.Information;
            case 'hint':
                return vscode.DiagnosticSeverity.Hint;
            default:
                return vscode.DiagnosticSeverity.Warning;
        }
    }

    /**
     * Get related information for a pattern
     */
    private getRelatedInformation(pattern: any): vscode.DiagnosticRelatedInformation[] {
        const relatedInfo: vscode.DiagnosticRelatedInformation[] = [];

        if (pattern.relatedPatterns && pattern.relatedPatterns.length > 0) {
            for (const related of pattern.relatedPatterns) {
                if (related.uri && related.range) {
                    relatedInfo.push(new vscode.DiagnosticRelatedInformation(
                        new vscode.Location(
                            vscode.Uri.parse(related.uri),
                            new vscode.Range(
                                related.range.start.line,
                                related.range.start.character,
                                related.range.end.line,
                                related.range.end.character
                            )
                        ),
                        related.message
                    ));
                }
            }
        }

        return relatedInfo;
    }

    public dispose(): void {
        this.diagnosticCollection.clear();
        this.diagnosticCollection.dispose();
        this.disposables.forEach(d => d.dispose());
    }
}
