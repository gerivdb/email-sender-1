// Fournisseur de diagnostics pour l'analyseur de patterns d'erreur
import * as vscode from 'vscode';

export class ErrorPatternDiagnosticsProvider {
  private collection: vscode.DiagnosticCollection;

  constructor() {
    this.collection = vscode.languages.createDiagnosticCollection('error-patterns');
  }

  public setDiagnostics(uri: vscode.Uri, diagnostics: vscode.Diagnostic[]) {
    this.collection.set(uri, diagnostics);
  }

  public clearDiagnostics(uri?: vscode.Uri) {
    if (uri) {
      this.collection.delete(uri);
    } else {
      this.collection.clear();
    }
  }
}
