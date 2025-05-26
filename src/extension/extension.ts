// Point d'entrée principal de l'extension VS Code
import * as vscode from 'vscode';
import { registerCommands } from './commands';

export function activate(context: vscode.ExtensionContext) {
  registerCommands(context);
}

export function deactivate() {}
