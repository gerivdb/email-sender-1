# Script pour organiser les fichiers MCP

Write-Host "=== Organisation des fichiers MCP ===" -ForegroundColor Cyan

# Creer le dossier mcp s'il n'existe pas
if (-not (Test-Path ".\mcp")) {
    New-Item -ItemType Directory -Path ".\mcp" | Out-Null
    Write-Host "âœ… Dossier mcp cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\batch s'il n'existe pas
if (-not (Test-Path ".\mcp\batch")) {
    New-Item -ItemType Directory -Path ".\mcp\batch" | Out-Null
    Write-Host "âœ… Dossier mcp\batch cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\batch existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\config s'il n'existe pas
if (-not (Test-Path ".\mcp\config")) {
    New-Item -ItemType Directory -Path ".\mcp\config" | Out-Null
    Write-Host "âœ… Dossier mcp\config cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\config existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\workflows s'il n'existe pas
if (-not (Test-Path ".\mcp\workflows")) {
    New-Item -ItemType Directory -Path ".\mcp\workflows" | Out-Null
    Write-Host "âœ… Dossier mcp\workflows cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\workflows existe deja" -ForegroundColor Green
}

# Deplacer les fichiers batch MCP
$batchFiles = @(
    "mcp-standard.cmd",
    "mcp-notion.cmd",
    "gateway.exe.cmd",
    "mcp-git-ingest.cmd"
)

foreach ($file in $batchFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\batch\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\batch" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Deplacer les fichiers de configuration MCP
$configFiles = @(
    "mcp-config.json",
    "mcp-config-fixed.json",
    "gateway.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\config\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\config" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Deplacer les workflows de test
$workflowFiles = @(
    "test-mcp-workflow-updated.json",
    "test-mcp-git-ingest-workflow.json"
)

foreach ($file in $workflowFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\workflows\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\workflows" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Creer un fichier README.md dans le dossier mcp
$readmePath = "repo\README.md"
$readmeContent = @"
# Configuration MCP pour n8n

Ce dossier contient tous les fichiers necessaires pour configurer et utiliser les MCP (Model Context Protocol) dans n8n.

## Structure des dossiers

- **batch** : Fichiers batch pour executer les differents MCP
- **config** : Fichiers de configuration pour les MCP
- **workflows** : Workflows de test pour les MCP

## MCP disponibles

- **MCP Standard** : Pour interagir avec OpenRouter et les modeles d'IA
- **MCP Notion** : Pour interagir avec vos bases de donnees Notion
- **MCP Gateway** : Pour interagir avec vos bases de donnees SQL
- **MCP Git Ingest** : Pour explorer et lire les depots GitHub

## Utilisation

1. Executez le script `scripts\configure-n8n-mcp.ps1` pour configurer les MCP Standard, Notion et Gateway
2. Executez le script `scripts\configure-mcp-git-ingest.ps1` pour configurer le MCP Git Ingest
3. Utilisez le script `start-n8n-complete.cmd` pour demarrer n8n avec verification des MCP

## Documentation

Pour plus d'informations, consultez les guides suivants :

- [Guide final MCP](../GUIDE_FINAL_MCP.md)
- [Guide MCP Gateway](../GUIDE_MCP_GATEWAY.md)
- [Guide MCP Git Ingest](../GUIDE_MCP_GIT_INGEST.md)
"@

Set-Content -Path $readmePath -Value $readmeContent
Write-Host "âœ… Fichier README.md cree dans le dossier mcp" -ForegroundColor Green

# Creer un script pour utiliser les MCP depuis le dossier mcp
$scriptPath = "..\..\D"
$scriptContent = @"
# Script pour utiliser les MCP depuis le dossier mcp

# Definir les variables d'environnement
`$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')

# Fonction pour executer un MCP

# Script pour organiser les fichiers MCP

Write-Host "=== Organisation des fichiers MCP ===" -ForegroundColor Cyan

# Creer le dossier mcp s'il n'existe pas
if (-not (Test-Path ".\mcp")) {
    New-Item -ItemType Directory -Path ".\mcp" | Out-Null
    Write-Host "âœ… Dossier mcp cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\batch s'il n'existe pas
if (-not (Test-Path ".\mcp\batch")) {
    New-Item -ItemType Directory -Path ".\mcp\batch" | Out-Null
    Write-Host "âœ… Dossier mcp\batch cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\batch existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\config s'il n'existe pas
if (-not (Test-Path ".\mcp\config")) {
    New-Item -ItemType Directory -Path ".\mcp\config" | Out-Null
    Write-Host "âœ… Dossier mcp\config cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\config existe deja" -ForegroundColor Green
}

# Creer le dossier mcp\workflows s'il n'existe pas
if (-not (Test-Path ".\mcp\workflows")) {
    New-Item -ItemType Directory -Path ".\mcp\workflows" | Out-Null
    Write-Host "âœ… Dossier mcp\workflows cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier mcp\workflows existe deja" -ForegroundColor Green
}

# Deplacer les fichiers batch MCP
$batchFiles = @(
    "mcp-standard.cmd",
    "mcp-notion.cmd",
    "gateway.exe.cmd",
    "mcp-git-ingest.cmd"
)

foreach ($file in $batchFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\batch\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\batch" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Deplacer les fichiers de configuration MCP
$configFiles = @(
    "mcp-config.json",
    "mcp-config-fixed.json",
    "gateway.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\config\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\config" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Deplacer les workflows de test
$workflowFiles = @(
    "test-mcp-workflow-updated.json",
    "test-mcp-git-ingest-workflow.json"
)

foreach ($file in $workflowFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\mcp\workflows\$file"
        Write-Host "âœ… Fichier $file copie dans mcp\workflows" -ForegroundColor Green
    } else {
        Write-Host "âŒ Fichier $file non trouve" -ForegroundColor Red
    }
}

# Creer un fichier README.md dans le dossier mcp
$readmePath = "repo\README.md"
$readmeContent = @"
# Configuration MCP pour n8n

Ce dossier contient tous les fichiers necessaires pour configurer et utiliser les MCP (Model Context Protocol) dans n8n.

## Structure des dossiers

- **batch** : Fichiers batch pour executer les differents MCP
- **config** : Fichiers de configuration pour les MCP
- **workflows** : Workflows de test pour les MCP

## MCP disponibles

- **MCP Standard** : Pour interagir avec OpenRouter et les modeles d'IA
- **MCP Notion** : Pour interagir avec vos bases de donnees Notion
- **MCP Gateway** : Pour interagir avec vos bases de donnees SQL
- **MCP Git Ingest** : Pour explorer et lire les depots GitHub

## Utilisation

1. Executez le script `scripts\configure-n8n-mcp.ps1` pour configurer les MCP Standard, Notion et Gateway
2. Executez le script `scripts\configure-mcp-git-ingest.ps1` pour configurer le MCP Git Ingest
3. Utilisez le script `start-n8n-complete.cmd` pour demarrer n8n avec verification des MCP

## Documentation

Pour plus d'informations, consultez les guides suivants :

- [Guide final MCP](../GUIDE_FINAL_MCP.md)
- [Guide MCP Gateway](../GUIDE_MCP_GATEWAY.md)
- [Guide MCP Git Ingest](../GUIDE_MCP_GIT_INGEST.md)
"@

Set-Content -Path $readmePath -Value $readmeContent
Write-Host "âœ… Fichier README.md cree dans le dossier mcp" -ForegroundColor Green

# Creer un script pour utiliser les MCP depuis le dossier mcp
$scriptPath = "..\..\D"
$scriptContent = @"
# Script pour utiliser les MCP depuis le dossier mcp

# Definir les variables d'environnement
`$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')

# Fonction pour executer un MCP
function Execute-MCP {
    param (
        [Parameter(Mandatory=`$true)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]`$MCP,
        
        [Parameter(Mandatory=`$false)]
        [string]`$Args = ""
    )
    
    switch (`$MCP) {
        "standard" {
            Write-Host "Execution du MCP Standard..." -ForegroundColor Cyan
            & "..\..\D" `$Args
        }
        "notion" {
            Write-Host "Execution du MCP Notion..." -ForegroundColor Cyan
            & "..\..\D" `$Args
        }
        "gateway" {
            Write-Host "Execution du MCP Gateway..." -ForegroundColor Cyan
            & "..\email\gateway.exe.cmd" `$Args
        }
        "git-ingest" {
            Write-Host "Execution du MCP Git Ingest..." -ForegroundColor Cyan
            & "..\..\D" `$Args
        }
        default {
            Write-Host "MCP non reconnu : `$MCP" -ForegroundColor Red
            Write-Host "MCPs disponibles : standard, notion, gateway, git-ingest" -ForegroundColor Yellow
        }
    }
}

# Verifier les arguments
if (`$args.Count -eq 0) {
    Write-Host "Usage : .\use-mcp.ps1 <mcp> [args]" -ForegroundColor Yellow
    Write-Host "MCPs disponibles : standard, notion, gateway, git-ingest" -ForegroundColor Yellow
    exit
}

# Executer le MCP
`$mcpName = `$args[0]
`$mcpArgs = `$args[1..`$args.Count] -join " "

Execute-MCP -MCP `$mcpName -Args `$mcpArgs
"@

Set-Content -Path $scriptPath -Value $scriptContent
Write-Host "âœ… Script use-mcp.ps1 cree dans le dossier mcp" -ForegroundColor Green

Write-Host "`n=== Organisation terminee ===" -ForegroundColor Cyan
Write-Host "Les fichiers MCP ont ete organises dans le dossier mcp."
Write-Host "Vous pouvez maintenant utiliser les MCP depuis ce dossier."



}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
