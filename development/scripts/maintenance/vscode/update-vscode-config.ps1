# Script pour mettre Ã  jour la configuration VS Code
$settingsContent = @'
{
    "mcpServers": {
        "filesystem": {
            "command": "npx",
            "args": [
                "-y",
                "@modelcontextprotocol/server-filesystem",
                "D:\\\\DO\\\\WEB\\\\N8N_tests\\\\PROJETS\\\\EMAIL_SENDER_1\\\\"
            ]
        },
        "github": {
            "command": "npx",
            "args": [
                "-y",
                "@modelcontextprotocol/server-github",
                "--config",
                "D:\\\\DO\\\\WEB\\\\N8N_tests\\\\PROJETS\\\\EMAIL_SENDER_1\\\\mcp-servers\\\\github\\\\config.json"
            ]
        },
        "supergateway": {
            "command": "npx",
            "args": [
                "-y",
                "supergateway",
                "start",
                "--config",
                "D:\\\\DO\\\\WEB\\\\N8N_tests\\\\PROJETS\\\\EMAIL_SENDER_1\\\\src\\\\mcp\\\\config\\\\gateway.yaml",
                "mcp-stdio"
            ]
        }
    },
    "notifications.excludeWarnings": [
        "*MCP server*",
        "*modelcontextprotocol*",
        "*supergateway*"
    ],

    // ParamÃ¨tres d'Ã©diteur optimisÃ©s
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80, 120],
    "editor.wordWrap": "on",
    "editor.suggestSelection": "first",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.minimap.enabled": false,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.linkedEditing": true,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.fontLigatures": true,

    // Optimisations de performance
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/*.pyc": true
    },
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/.hg/store/**": true,
        "**/dist/**": true,
        "**/__pycache__/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/*.code-search": true,
        "**/dist": true,
        "**/.git": true
    },
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 10,
    "workbench.editor.enablePreview": false,
    "workbench.list.smoothScrolling": true,
    "workbench.tree.indent": 16,

    // Configuration des langages
    // PowerShell
    "powershell.codeFormatting.useCorrectCasing": true,
    "powershell.codeFormatting.autoCorrectAliases": true,
    "powershell.codeFormatting.trimWhitespaceAroundPipe": true,
    "powershell.integratedConsole.focusConsoleOnExecute": false,
    "powershell.pester.useLegacyCodeLens": false,
    "powershell.promptToUpdatePowerShell": true,
    "powershell.startAutomatically": true,

    // Python
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "python.testing.pytestEnabled": true,
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.autoImportCompletions": true,

    // Terminal
    "terminal.integrated.scrollback": 10000,
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.copyOnSelection": true,

    // Git
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,
    "diffEditor.ignoreTrimWhitespace": false,
    "diffEditor.renderSideBySide": true,

    // Autres optimisations
    "explorer.compactFolders": false,
    "explorer.confirmDelete": true,
    "explorer.confirmDragAndDrop": false
}
'@

$keybindingsContent = @'
[
  {
    "key": "ctrl+alt+j d",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: EntrÃ©e quotidienne"
  },
  {
    "key": "ctrl+alt+j w",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: EntrÃ©e hebdomadaire"
  },
  {
    "key": "ctrl+alt+j n",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: Nouvelle entrÃ©e"
  },
  {
    "key": "ctrl+alt+j s",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: Rechercher"
  },
  {
    "key": "ctrl+alt+j r",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: Reconstruire l'index"
  },
  {
    "key": "ctrl+alt+j q",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: Interroger le RAG"
  },
  {
    "key": "ctrl+alt+j m",
    "command": "workbench.action.tasks.runTask",
    "args": "Journal: DÃ©marrer la surveillance"
  }
]
'@

# CrÃ©er le dossier .vscode s'il n'existe pas
if (-not (Test-Path -Path ".vscode")) {
    New-Item -Path ".vscode" -ItemType Directory -Force | Out-Null
    Write-Host "Dossier .vscode crÃ©Ã©."
}

# Ã‰crire les fichiers de configuration
try {
    $settingsContent | Out-File -FilePath ".vscode/settings.json" -Encoding utf8 -Force
    Write-Host "Fichier settings.json mis Ã  jour avec succÃ¨s."
    
    $keybindingsContent | Out-File -FilePath ".vscode/keybindings.json" -Encoding utf8 -Force
    Write-Host "Fichier keybindings.json mis Ã  jour avec succÃ¨s."
    
    Write-Host "Configuration VS Code optimisÃ©e avec succÃ¨s !"
} catch {
    Write-Error "Erreur lors de la mise Ã  jour des fichiers : $_"
}
