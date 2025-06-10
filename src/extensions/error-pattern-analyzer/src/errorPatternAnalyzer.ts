import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import * as child_process from 'child_process';

/**
 * Analyzer for error patterns in PowerShell files
 */
export class ErrorPatternAnalyzer implements vscode.Disposable {
    private context: vscode.ExtensionContext | null;
    private patternDatabase: any[] = [];

    constructor(context: vscode.ExtensionContext | null = null) {
        this.context = context;
        this.loadPatternDatabase();
    }

    /**
     * Load the error pattern database
     */
    private loadPatternDatabase(): void {
        try {
            // Try to load from configuration if in VS Code environment
            if (this.context && vscode.workspace) {
                const config = vscode.workspace.getConfiguration('errorPatternAnalyzer');
                const databasePath = config.get<string>('databasePath', '');

                if (databasePath && fs.existsSync(databasePath)) {
                    try {
                        const data = fs.readFileSync(databasePath, 'utf8');
                        this.patternDatabase = JSON.parse(data);
                        console.log(`Loaded ${this.patternDatabase.length} patterns from database`);
                        return;
                    } catch (error) {
                        console.error('Error loading pattern database:', error);
                        if (vscode.window) {
                            vscode.window.showErrorMessage(`Error loading pattern database: ${error}`);
                        }
                    }
                }
            }
        } catch (error) {
            console.error('Error accessing VS Code API:', error);
        }

        // Use default patterns for demonstration
        this.patternDatabase = [
                {
                    id: 'null-reference',
                    pattern: 'Cannot access property .* of null object',
                    message: 'Potential null reference error',
                    severity: 'error',
                    description: 'This error occurs when trying to access a property of a null object',
                    suggestion: 'Check if the object is null before accessing its properties',
                    codeExample: 'if ($object -ne $null -and $object.Property) { ... }',
                    relatedPatterns: []
                },
                {
                    id: 'index-out-of-bounds',
                    pattern: 'Index was outside the bounds of the array',
                    message: 'Array index out of bounds',
                    severity: 'error',
                    description: 'This error occurs when trying to access an array element with an invalid index',
                    suggestion: 'Check the array length before accessing elements',
                    codeExample: 'if ($array.Length -gt $index) { ... }',
                    relatedPatterns: []
                },                {
                    id: 'type-conversion',
                    pattern: 'Cannot convert value .* to type',
                    message: 'Type conversion error',
                    severity: 'error',
                    description: 'This error occurs when trying to convert a value to an incompatible type',
                    suggestion: 'Use explicit type conversion or check the value type',
                    codeExample: 'if ($value -as [System.Int32]) { $intValue = [System.Int32]$value }',
                    relatedPatterns: []
                }
            ];
            console.log('Using default pattern database');
        }

    /**
     * Analyze a document for error patterns
     */
    public analyzeDocument(document: vscode.TextDocument): any[] {
        const results: any[] = [];
        const text = document.getText();
        const lines = text.split(/\r?\n/);

        // Analyze each line for patterns
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Check each pattern
            for (const pattern of this.patternDatabase) {
                const regex = new RegExp(pattern.pattern, 'i');
                const match = regex.exec(line);

                if (match) {
                    results.push({
                        id: pattern.id,
                        lineNumber: i,
                        startColumn: match.index,
                        endColumn: match.index + match[0].length,
                        message: pattern.message,
                        severity: pattern.severity,
                        description: pattern.description,
                        suggestion: pattern.suggestion,
                        codeExample: pattern.codeExample,
                        relatedPatterns: pattern.relatedPatterns
                    });
                }
            }
        }

        return results;
    }

    /**
     * Analyze a document using the PowerShell module
     */
    public async analyzeWithPowerShell(document: vscode.TextDocument): Promise<any[]> {
        return new Promise((resolve, reject) => {
            try {
                if (!this.context) {
                    reject('Extension context is not available');
                    return;
                }

                // Get the path to the PowerShell module
                const modulePath = path.join(this.context.extensionPath, 'scripts', 'ErrorPatternAnalyzer.psm1');

                // Create a temporary file for the document
                const tempFile = path.join(this.context.extensionPath, 'temp', 'temp.ps1');
                fs.mkdirSync(path.dirname(tempFile), { recursive: true });
                fs.writeFileSync(tempFile, document.getText());

                // Create the PowerShell command
                const command = `
                    Import-Module "${modulePath}" -Force;
                    $results = Analyze-ErrorPatterns -FilePath "${tempFile}";
                    ConvertTo-Json -InputObject $results -Depth 10
                `;

                // Execute the PowerShell command
                const ps = child_process.spawn('powershell', ['-Command', command]);

                let stdout = '';
                let stderr = '';

                ps.stdout.on('data', (data) => {
                    stdout += data.toString();
                });

                ps.stderr.on('data', (data) => {
                    stderr += data.toString();
                });

                ps.on('close', (code) => {
                    // Clean up the temporary file
                    try {
                        fs.unlinkSync(tempFile);
                    } catch (error) {
                        console.error('Error cleaning up temporary file:', error);
                    }

                    if (code === 0) {
                        try {
                            const results = JSON.parse(stdout);
                            resolve(results);
                        } catch (error) {
                            reject(`Error parsing PowerShell output: ${error}`);
                        }
                    } else {
                        reject(`PowerShell exited with code ${code}: ${stderr}`);
                    }
                });
            } catch (error) {
                reject(`Error analyzing with PowerShell: ${error}`);
            }
        });
    }

    public dispose(): void {
        // Nothing to dispose
    }
}
