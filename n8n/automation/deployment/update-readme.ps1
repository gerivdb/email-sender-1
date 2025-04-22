<#
.SYNOPSIS
    Script pour mettre à jour le fichier README.md à la racine du projet.

.DESCRIPTION
    Ce script met à jour le fichier README.md à la racine du projet pour indiquer la nouvelle structure n8n.

.EXAMPLE
    .\update-readme.ps1
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$readmePath = Join-Path -Path $rootPath -ChildPath "README.md"
$n8nReadmePath = Join-Path -Path $rootPath -ChildPath "n8n-new\README.md"

# Vérifier si le fichier README.md existe
if (Test-Path -Path $readmePath) {
    # Lire le contenu du fichier README.md
    $readmeContent = Get-Content -Path $readmePath -Raw
    
    # Vérifier si le fichier contient déjà des informations sur n8n
    if ($readmeContent -match "n8n") {
        # Mettre à jour les informations sur n8n
        $n8nSection = @"

## n8n - Workflow Automation

Ce projet utilise n8n pour l'automatisation des workflows. La structure n8n a été réorganisée pour une meilleure organisation et maintenance.

### Structure

```
n8n/
├── config/               # Configuration n8n
├── data/                 # Données n8n (base de données, credentials, etc.)
├── workflows/            # Workflows n8n
│   ├── local/            # Workflows utilisés par n8n local
│   ├── ide/              # Workflows utilisés par l'IDE
│   └── archive/          # Workflows archivés
├── scripts/              # Scripts utilitaires
├── integrations/         # Intégrations avec d'autres systèmes
├── docs/                 # Documentation
└── cmd/                  # Scripts de commande Windows
    ├── install/          # Scripts d'installation
    ├── start/            # Scripts de démarrage
    ├── stop/             # Scripts d'arrêt
    └── utils/            # Scripts utilitaires
```

### Utilisation

Pour installer n8n, exécutez:

```
.\n8n\cmd\install\install-n8n-local.cmd
```

Pour démarrer n8n, exécutez:

```
.\n8n\cmd\start\start-n8n-local.cmd
```

Pour arrêter n8n, exécutez:

```
.\n8n\cmd\stop\stop-n8n.cmd
```

Pour plus d'informations, consultez la documentation dans le dossier [n8n/docs/](n8n/docs/).

"@
        
        # Remplacer la section n8n existante ou ajouter la nouvelle section
        if ($readmeContent -match "(?s)## n8n.*?(?=##|$)") {
            $readmeContent = $readmeContent -replace "(?s)## n8n.*?(?=##|$)", $n8nSection
        } else {
            $readmeContent += "`n$n8nSection"
        }
    } else {
        # Ajouter des informations sur n8n
        $n8nSection = @"

## n8n - Workflow Automation

Ce projet utilise n8n pour l'automatisation des workflows. La structure n8n a été réorganisée pour une meilleure organisation et maintenance.

### Structure

```
n8n/
├── config/               # Configuration n8n
├── data/                 # Données n8n (base de données, credentials, etc.)
├── workflows/            # Workflows n8n
│   ├── local/            # Workflows utilisés par n8n local
│   ├── ide/              # Workflows utilisés par l'IDE
│   └── archive/          # Workflows archivés
├── scripts/              # Scripts utilitaires
├── integrations/         # Intégrations avec d'autres systèmes
├── docs/                 # Documentation
└── cmd/                  # Scripts de commande Windows
    ├── install/          # Scripts d'installation
    ├── start/            # Scripts de démarrage
    ├── stop/             # Scripts d'arrêt
    └── utils/            # Scripts utilitaires
```

### Utilisation

Pour installer n8n, exécutez:

```
.\n8n\cmd\install\install-n8n-local.cmd
```

Pour démarrer n8n, exécutez:

```
.\n8n\cmd\start\start-n8n-local.cmd
```

Pour arrêter n8n, exécutez:

```
.\n8n\cmd\stop\stop-n8n.cmd
```

Pour plus d'informations, consultez la documentation dans le dossier [n8n/docs/](n8n/docs/).

"@
        
        $readmeContent += $n8nSection
    }
    
    # Enregistrer le fichier README.md
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    
    Write-Host "Fichier README.md mis à jour: $readmePath"
} else {
    # Créer un nouveau fichier README.md
    $readmeContent = @"
# EMAIL_SENDER_1

## n8n - Workflow Automation

Ce projet utilise n8n pour l'automatisation des workflows. La structure n8n a été réorganisée pour une meilleure organisation et maintenance.

### Structure

```
n8n/
├── config/               # Configuration n8n
├── data/                 # Données n8n (base de données, credentials, etc.)
├── workflows/            # Workflows n8n
│   ├── local/            # Workflows utilisés par n8n local
│   ├── ide/              # Workflows utilisés par l'IDE
│   └── archive/          # Workflows archivés
├── scripts/              # Scripts utilitaires
├── integrations/         # Intégrations avec d'autres systèmes
├── docs/                 # Documentation
└── cmd/                  # Scripts de commande Windows
    ├── install/          # Scripts d'installation
    ├── start/            # Scripts de démarrage
    ├── stop/             # Scripts d'arrêt
    └── utils/            # Scripts utilitaires
```

### Utilisation

Pour installer n8n, exécutez:

```
.\n8n\cmd\install\install-n8n-local.cmd
```

Pour démarrer n8n, exécutez:

```
.\n8n\cmd\start\start-n8n-local.cmd
```

Pour arrêter n8n, exécutez:

```
.\n8n\cmd\stop\stop-n8n.cmd
```

Pour plus d'informations, consultez la documentation dans le dossier [n8n/docs/](n8n/docs/).
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    
    Write-Host "Fichier README.md créé: $readmePath"
}

# Mettre à jour le fichier README.md dans le dossier n8n
if (Test-Path -Path $n8nReadmePath) {
    # Lire le contenu du fichier README.md
    $n8nReadmeContent = Get-Content -Path $n8nReadmePath -Raw
    
    # Ajouter des informations sur les scripts de commande Windows
    if (-not ($n8nReadmeContent -match "cmd/")) {
        $cmdSection = @"

## Scripts de commande Windows

Des scripts de commande Windows sont disponibles dans le dossier [cmd/](cmd/) pour faciliter l'utilisation de n8n:

### Installation

- [install-n8n-local.cmd](cmd/install/install-n8n-local.cmd) : Installe n8n en local
- [install-community-nodes.cmd](cmd/install/install-community-nodes.cmd) : Installe les nœuds communautaires
- [install-mcp-client.cmd](cmd/install/install-mcp-client.cmd) : Installe le client MCP

### Démarrage

- [start-n8n-local.cmd](cmd/start/start-n8n-local.cmd) : Démarre n8n en local
- [start-n8n-debug.cmd](cmd/start/start-n8n-debug.cmd) : Démarre n8n en mode debug
- [start-n8n-tunnel.cmd](cmd/start/start-n8n-tunnel.cmd) : Démarre n8n avec tunnel
- [start-n8n-no-auth.cmd](cmd/start/start-n8n-no-auth.cmd) : Démarre n8n sans authentification

### Arrêt

- [stop-n8n.cmd](cmd/stop/stop-n8n.cmd) : Arrête n8n

### Utilitaires

- [sync-workflows.cmd](cmd/utils/sync-workflows.cmd) : Synchronise les workflows
- [create-test-workflow.cmd](cmd/utils/create-test-workflow.cmd) : Crée un workflow de test
- [reset-n8n.cmd](cmd/utils/reset-n8n.cmd) : Réinitialise n8n
"@
        
        $n8nReadmeContent += $cmdSection
        
        # Enregistrer le fichier README.md
        Set-Content -Path $n8nReadmePath -Value $n8nReadmeContent -Encoding UTF8
        
        Write-Host "Fichier README.md mis à jour: $n8nReadmePath"
    }
}

Write-Host ""
Write-Host "Mise à jour des fichiers README.md terminée."
