# Script pour organiser les outils de gestion des caractÃ¨res accentuÃ©s

# CrÃ©ation des rÃ©pertoires nÃ©cessaires
$directories = @(
    "development/scripts/maintenance/encoding",
    "development/scripts/maintenance/encoding/python",
    "development/scripts/maintenance/encoding/powershell",
    "development/scripts/maintenance/encoding/logs"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "RÃ©pertoire crÃ©Ã©: $dir" -ForegroundColor Green
    }
}

# DÃ©placement des scripts Python
$pythonScripts = @(
    "fix_all_workflows.py",
    "fix_encoding_simple.py",
    "fix_workflow_names.py",
    "list_n8n_workflows.py",
    "remove_accents.py"
)

foreach ($script in $pythonScripts) {
    if (Test-Path $script) {
        Copy-Item $script -Destination "development/scripts/maintenance/encoding/python/" -Force
        Write-Host "Script Python copiÃ©: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script Python non trouvÃ©: $script" -ForegroundColor Yellow
    }
}

# DÃ©placement des scripts PowerShell
$powershellScripts = @(
    "import-fixed-all-workflows.ps1",
    "remove-duplicate-workflows.ps1",
    "delete-all-workflows-auto.ps1",
    "list-workflows.ps1",
    "get-workflows.ps1",
    "fix-encoding-utf8.ps1",
    "fix-workflow-names.ps1"
)

foreach ($script in $powershellScripts) {
    if (Test-Path $script) {
        Copy-Item $script -Destination "development/scripts/maintenance/encoding/powershell/" -Force
        Write-Host "Script PowerShell copiÃ©: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script PowerShell non trouvÃ©: $script" -ForegroundColor Yellow
    }
}

# CrÃ©ation d'un script de lancement rapide
$launchScript = @"
# Script de lancement rapide pour les outils de gestion des caractÃ¨res accentuÃ©s


# Script pour organiser les outils de gestion des caractÃ¨res accentuÃ©s

# CrÃ©ation des rÃ©pertoires nÃ©cessaires
$directories = @(
    "development/scripts/maintenance/encoding",
    "development/scripts/maintenance/encoding/python",
    "development/scripts/maintenance/encoding/powershell",
    "development/scripts/maintenance/encoding/logs"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "RÃ©pertoire crÃ©Ã©: $dir" -ForegroundColor Green
    }
}

# DÃ©placement des scripts Python
$pythonScripts = @(
    "fix_all_workflows.py",
    "fix_encoding_simple.py",
    "fix_workflow_names.py",
    "list_n8n_workflows.py",
    "remove_accents.py"
)

foreach ($script in $pythonScripts) {
    if (Test-Path $script) {
        Copy-Item $script -Destination "development/scripts/maintenance/encoding/python/" -Force
        Write-Host "Script Python copiÃ©: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script Python non trouvÃ©: $script" -ForegroundColor Yellow
    }
}

# DÃ©placement des scripts PowerShell
$powershellScripts = @(
    "import-fixed-all-workflows.ps1",
    "remove-duplicate-workflows.ps1",
    "delete-all-workflows-auto.ps1",
    "list-workflows.ps1",
    "get-workflows.ps1",
    "fix-encoding-utf8.ps1",
    "fix-workflow-names.ps1"
)

foreach ($script in $powershellScripts) {
    if (Test-Path $script) {
        Copy-Item $script -Destination "development/scripts/maintenance/encoding/powershell/" -Force
        Write-Host "Script PowerShell copiÃ©: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script PowerShell non trouvÃ©: $script" -ForegroundColor Yellow
    }
}

# CrÃ©ation d'un script de lancement rapide
$launchScript = @"
# Script de lancement rapide pour les outils de gestion des caractÃ¨res accentuÃ©s

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
    [ValidateSet("fix", "import", "remove-duplicates", "list", "delete-all")]
    [string]`$Action
)

`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path

switch (`$Action) {
    "fix" {
        Write-Host "Correction des caractÃ¨res accentuÃ©s dans les fichiers JSON..." -ForegroundColor Cyan
        python `$scriptPath/python/fix_all_workflows.py
    }
    "import" {
        Write-Host "Importation des workflows corrigÃ©s..." -ForegroundColor Cyan
        & `$scriptPath/powershell/import-fixed-all-workflows.ps1
    }
    "remove-duplicates" {
        Write-Host "Suppression des doublons et des workflows mal encodÃ©s..." -ForegroundColor Cyan
        & `$scriptPath/powershell/remove-duplicate-workflows.ps1
    }
    "list" {
        Write-Host "Liste des workflows existants..." -ForegroundColor Cyan
        & `$scriptPath/powershell/list-workflows.ps1
    }
    "delete-all" {
        Write-Host "Suppression de tous les workflows existants..." -ForegroundColor Cyan
        & `$scriptPath/powershell/delete-all-workflows-auto.ps1
    }
}
"@

$launchScript | Out-File -FilePath "development/scripts/maintenance/encoding/encoding-tools.ps1" -Encoding utf8
Write-Host "Script de lancement rapide crÃ©Ã©: development/scripts/maintenance/encoding/encoding-tools.ps1" -ForegroundColor Green

# CrÃ©ation d'un fichier README pour le rÃ©pertoire
$readmeContent = @"
# Outils de gestion des caractÃ¨res accentuÃ©s franÃ§ais dans n8n

Ce rÃ©pertoire contient des scripts et des outils pour rÃ©soudre les problÃ¨mes d'encodage des caractÃ¨res accentuÃ©s franÃ§ais dans les workflows n8n.

## Utilisation rapide

Utilisez le script `encoding-tools.ps1` pour lancer rapidement les outils :

```powershell
# Correction des caractÃ¨res accentuÃ©s
.\encoding-tools.ps1 -Action fix

# Importation des workflows corrigÃ©s
.\encoding-tools.ps1 -Action import

# Suppression des doublons et des workflows mal encodÃ©s
.\encoding-tools.ps1 -Action remove-duplicates

# Liste des workflows existants
.\encoding-tools.ps1 -Action list

# Suppression de tous les workflows existants
.\encoding-tools.ps1 -Action delete-all
```

## Structure du rÃ©pertoire

- **python/** - Scripts Python pour la correction des caractÃ¨res accentuÃ©s
  - `fix_all_workflows.py` - Remplace les caractÃ¨res accentuÃ©s dans les fichiers JSON
  - `fix_encoding_simple.py` - Version simplifiÃ©e du script de correction d'encodage
  - `fix_workflow_names.py` - Se concentre sur la correction des noms des workflows
  - `list_n8n_workflows.py` - Liste les workflows prÃ©sents dans l'instance n8n
  - `remove_accents.py` - Utilitaire pour remplacer les caractÃ¨res accentuÃ©s

- **powershell/** - Scripts PowerShell pour l'interaction avec n8n
  - `import-fixed-all-workflows.ps1` - Importe les workflows corrigÃ©s dans n8n
  - `remove-duplicate-workflows.ps1` - Supprime les workflows en double ou mal encodÃ©s
  - `delete-all-workflows-auto.ps1` - Supprime tous les workflows existants sans confirmation
  - `list-workflows.ps1` - Liste les workflows existants dans n8n
  - `get-workflows.ps1` - RÃ©cupÃ¨re les dÃ©tails des workflows via l'API n8n
  - `fix-encoding-utf8.ps1` - Corrige l'encodage des fichiers JSON en UTF-8 avec BOM
  - `fix-workflow-names.ps1` - Corrige les noms des workflows

- **logs/** - Logs des opÃ©rations effectuÃ©es

## Documentation

Pour plus d'informations, consultez le guide complet : [Guide de gestion des caractÃ¨res accentuÃ©s franÃ§ais dans n8n](../../../docs/guides/GUIDE_GESTION_CARACTERES_ACCENTES.md)
"@

$readmeContent | Out-File -FilePath "development/scripts/maintenance/encoding/README.md" -Encoding utf8
Write-Host "Fichier README crÃ©Ã©: development/scripts/maintenance/encoding/README.md" -ForegroundColor Green

Write-Host "`nOrganisation des outils de gestion des caractÃ¨res accentuÃ©s terminÃ©e !" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le script de lancement rapide : development/scripts/maintenance/encoding/encoding-tools.ps1" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
