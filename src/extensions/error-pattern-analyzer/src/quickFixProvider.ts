import * as vscode from 'vscode';

/**
 * Provider for quick fixes for error patterns
 */
export class QuickFixProvider implements vscode.Disposable {
    private context: vscode.ExtensionContext;
    private disposables: vscode.Disposable[] = [];

    constructor(context: vscode.ExtensionContext) {
        this.context = context;

        // Register code action provider
        this.disposables.push(
            vscode.languages.registerCodeActionsProvider(
                { language: 'powershell' },
                new ErrorPatternCodeActionProvider(),
                {
                    providedCodeActionKinds: [
                        vscode.CodeActionKind.QuickFix
                    ]
                }
            )
        );
    }

    public dispose(): void {
        this.disposables.forEach(d => d.dispose());
    }
}

/**
 * Code action provider for error patterns
 */
class ErrorPatternCodeActionProvider implements vscode.CodeActionProvider {
    public provideCodeActions(
        document: vscode.TextDocument,
        range: vscode.Range | vscode.Selection,
        context: vscode.CodeActionContext,
        token: vscode.CancellationToken
    ): vscode.CodeAction[] | undefined {
        const actions: vscode.CodeAction[] = [];

        // Process each diagnostic
        for (const diagnostic of context.diagnostics) {
            // Only process diagnostics from our extension
            if (diagnostic.source !== 'Error Pattern Analyzer') {
                continue;
            }

            // Create actions based on the diagnostic code
            switch (diagnostic.code) {
                case 'null-reference':
                    actions.push(this.createNullCheckAction(document, diagnostic));
                    break;
                case 'index-out-of-bounds':
                    actions.push(this.createBoundsCheckAction(document, diagnostic));
                    break;
                case 'type-conversion':
                    actions.push(this.createTypeConversionAction(document, diagnostic));
                    break;
            }
        }

        return actions;
    }

    /**
     * Create a code action for null reference errors
     */
    private createNullCheckAction(document: vscode.TextDocument, diagnostic: vscode.Diagnostic): vscode.CodeAction {
        const action = new vscode.CodeAction('Add null check', vscode.CodeActionKind.QuickFix);
        action.diagnostics = [diagnostic];
        action.isPreferred = true;

        // Get the line text
        const line = document.lineAt(diagnostic.range.start.line);
        const lineText = line.text;

        // Extract the object name (assuming it's a variable followed by a dot)
        const match = /(\$\w+)\./.exec(lineText);
        if (match) {
            const objectName = match[1];
            
            // Create the edit
            const edit = new vscode.WorkspaceEdit();
            const newText = `if (${objectName} -ne $null) { ${lineText} }`;
            
            edit.replace(
                document.uri,
                line.range,
                newText
            );
            
            action.edit = edit;
        }

        return action;
    }

    /**
     * Create a code action for index out of bounds errors
     */
    private createBoundsCheckAction(document: vscode.TextDocument, diagnostic: vscode.Diagnostic): vscode.CodeAction {
        const action = new vscode.CodeAction('Add bounds check', vscode.CodeActionKind.QuickFix);
        action.diagnostics = [diagnostic];
        action.isPreferred = true;

        // Get the line text
        const line = document.lineAt(diagnostic.range.start.line);
        const lineText = line.text;

        // Extract the array and index (assuming it's a variable followed by brackets)
        const match = /(\$\w+)\[(\$?\w+)\]/.exec(lineText);
        if (match) {
            const arrayName = match[1];
            const indexName = match[2];
            
            // Create the edit
            const edit = new vscode.WorkspaceEdit();
            const newText = `if (${arrayName}.Length -gt ${indexName}) { ${lineText} }`;
            
            edit.replace(
                document.uri,
                line.range,
                newText
            );
            
            action.edit = edit;
        }

        return action;
    }

    /**
     * Create a code action for type conversion errors
     */
    private createTypeConversionAction(document: vscode.TextDocument, diagnostic: vscode.Diagnostic): vscode.CodeAction {
        const action = new vscode.CodeAction('Add type check', vscode.CodeActionKind.QuickFix);
        action.diagnostics = [diagnostic];
        action.isPreferred = true;

        // Get the line text
        const line = document.lineAt(diagnostic.range.start.line);
        const lineText = line.text;

        // Extract the variable and type (assuming it's a cast operation)
        const match = /\[(\w+(\.\w+)*)\](\$\w+)/.exec(lineText);
        if (match) {
            const typeName = match[1];
            const varName = match[3];
            
            // Create the edit
            const edit = new vscode.WorkspaceEdit();
            const newText = `if (${varName} -as [${typeName}]) { ${lineText} }`;
            
            edit.replace(
                document.uri,
                line.range,
                newText
            );
            
            action.edit = edit;
        }

        return action;
    }
}
