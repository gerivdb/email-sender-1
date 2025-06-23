// Extension VS Code (esquisse, Go natif via CLI)
// Pour automatiser l’application du patch diff Edit, il suffit d’appeler le binaire Go depuis une tâche ou une commande personnalisée dans VS Code.

// Exemple de tâche VS Code (tasks.json) :
{
  "label": "Appliquer patch diff Edit (Go)",
  "type": "shell",
  "command": "go run ${workspaceFolder}/tools/diff_edit/go/diffedit.go --file ${file} --patch ${input:patchFile}",
  "problemMatcher": [],
  "group": "build"
}
// Ajouter une entrée dans "inputs" pour sélectionner le patch à appliquer.

// Pour une extension avancée, il est possible d’appeler le binaire Go via Node.js child_process ou d’intégrer le CLI Go dans une extension TypeScript, mais la logique métier reste 100% Go.
