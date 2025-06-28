const vscode = require('vscode');
const { exec } = require('child_process');

function activate(context) {
    let disposable = vscode.commands.registerCommand('extension.analyzeSelection', function () {
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const document = editor.document;
            const selection = editor.selection;
            const text = document.getText(selection);

            if (text.length === 0) {
                vscode.window.showInformationMessage('Aucune sélection détectée.');
                return;
            }

            // Get file path and selection line/offset
            const filePath = document.fileName;
            const startLine = selection.start.line + 1; // VSCode lines are 0-based
            const endLine = selection.end.line + 1;

            // Assuming read_file_navigator can take a file path and line range
            // For a real integration, you might need a small Go HTTP server or a more sophisticated CLI.
            // For this example, we'll just demonstrate calling a Go CLI with basic arguments.
            // You would replace 'read_file_navigator' with the actual compiled Go binary path.
            const command = `go run cmd/read_file_navigator/read_file_navigator.go --file="${filePath}" --action=range --start-line=${startLine} --end-line=${endLine}`;

            vscode.window.showInformationMessage(`Analyse de la sélection dans ${filePath} (Lignes ${startLine}-${endLine})...`);

            exec(command, (error, stdout, stderr) => {
                if (error) {
                    vscode.window.showErrorMessage(`Erreur lors de l'analyse: ${error.message}\n${stderr}`);
                    return;
                }
                vscode.window.showInformationMessage('Analyse terminée. Voir le panneau de sortie.');
                const outputChannel = vscode.window.createOutputChannel('Read File Analysis');
                outputChannel.appendLine(stdout);
                outputChannel.show();
            });

        } else {
            vscode.window.showInformationMessage('Aucun éditeur de texte actif.');
        }
    });

    context.subscriptions.push(disposable);
}

function deactivate() {}

module.exports = {
    activate,
    deactivate
}
