import * as vscode from 'vscode';
import { ErrorPatternAnalyzer } from './errorPatternAnalyzer';

/**
 * Explorer for error patterns
 */
export class ErrorPatternExplorer implements vscode.Disposable {
    private context: vscode.ExtensionContext;
    private analyzer: ErrorPatternAnalyzer;
    private treeDataProvider: ErrorPatternTreeDataProvider;

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
        this.analyzer = new ErrorPatternAnalyzer(context);
        this.treeDataProvider = new ErrorPatternTreeDataProvider(this.analyzer);

        // Register the tree data provider
        const treeView = vscode.window.createTreeView('errorPatterns', {
            treeDataProvider: this.treeDataProvider,
            showCollapseAll: true
        });

        context.subscriptions.push(treeView);
    }

    /**
     * Show error patterns in the explorer
     */
    public showErrorPatterns(): void {
        this.treeDataProvider.refresh();
    }

    public dispose(): void {
        // Nothing to dispose
    }
}

/**
 * Tree data provider for error patterns
 */
class ErrorPatternTreeDataProvider implements vscode.TreeDataProvider<ErrorPatternTreeItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<ErrorPatternTreeItem | undefined> = new vscode.EventEmitter<ErrorPatternTreeItem | undefined>();
    readonly onDidChangeTreeData: vscode.Event<ErrorPatternTreeItem | undefined> = this._onDidChangeTreeData.event;

    constructor(private analyzer: ErrorPatternAnalyzer) { }

    refresh(): void {
        this._onDidChangeTreeData.fire(undefined);
    }

    getTreeItem(element: ErrorPatternTreeItem): vscode.TreeItem {
        return element;
    }

    getChildren(element?: ErrorPatternTreeItem): Thenable<ErrorPatternTreeItem[]> {
        if (!element) {
            // Root level - get all patterns from open documents
            return this.getPatternsFromOpenDocuments();
        } else if (element.contextValue === 'document') {
            // Document level - get patterns for this document
            return this.getPatternsForDocument(element.resourceUri!);
        } else {
            // Pattern level - no children
            return Promise.resolve([]);
        }
    }

    /**
     * Get patterns from all open documents
     */
    private async getPatternsFromOpenDocuments(): Promise<ErrorPatternTreeItem[]> {
        const items: ErrorPatternTreeItem[] = [];

        for (const document of vscode.workspace.textDocuments) {
            if (document.languageId === 'powershell') {
                const patterns = this.analyzer.analyzeDocument(document);
                if (patterns.length > 0) {
                    const item = new ErrorPatternTreeItem(
                        path.basename(document.fileName),
                        vscode.TreeItemCollapsibleState.Collapsed,
                        document.uri
                    );
                    item.description = `${patterns.length} patterns`;
                    item.contextValue = 'document';
                    items.push(item);
                }
            }
        }

        return items;
    }

    /**
     * Get patterns for a specific document
     */
    private async getPatternsForDocument(uri: vscode.Uri): Promise<ErrorPatternTreeItem[]> {
        const items: ErrorPatternTreeItem[] = [];
        const document = await vscode.workspace.openTextDocument(uri);
        const patterns = this.analyzer.analyzeDocument(document);

        for (const pattern of patterns) {
            const item = new ErrorPatternTreeItem(
                pattern.message,
                vscode.TreeItemCollapsibleState.None,
                uri
            );
            item.description = `Line ${pattern.lineNumber + 1}`;
            item.tooltip = pattern.description;
            item.command = {
                command: 'vscode.open',
                arguments: [
                    uri,
                    {
                        selection: new vscode.Range(
                            pattern.lineNumber,
                            pattern.startColumn,
                            pattern.lineNumber,
                            pattern.endColumn
                        )
                    }
                ],
                title: 'Go to Pattern'
            };
            item.contextValue = 'pattern';
            item.iconPath = this.getIconForSeverity(pattern.severity);
            items.push(item);
        }

        return items;
    }

    /**
     * Get icon for a severity level
     */
    private getIconForSeverity(severity: string): vscode.ThemeIcon {
        switch (severity) {
            case 'error':
                return new vscode.ThemeIcon('error');
            case 'warning':
                return new vscode.ThemeIcon('warning');
            case 'information':
                return new vscode.ThemeIcon('info');
            case 'hint':
                return new vscode.ThemeIcon('lightbulb');
            default:
                return new vscode.ThemeIcon('warning');
        }
    }
}

/**
 * Tree item for error patterns
 */
class ErrorPatternTreeItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly resourceUri?: vscode.Uri
    ) {
        super(label, collapsibleState);
    }
}

// Import path module
import * as path from 'path';
