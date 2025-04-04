# Script pour organiser les outils de gestion des caractères accentués

# Création des répertoires nécessaires
$directories = @(
    "scripts/maintenance/encoding",
    "scripts/maintenance/encoding/python",
    "scripts/maintenance/encoding/powershell",
    "scripts/maintenance/encoding/logs"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Répertoire créé: $dir" -ForegroundColor Green
    }
}

# Déplacement des scripts Python
$pythonScripts = @(
    "fix_all_workflows.py",
    "fix_encoding_simple.py",
    "fix_workflow_names.py",
    "list_n8n_workflows.py",
    "remove_accents.py"
)

foreach ($script in $pythonScripts) {
    if (Test-Path $script) {
        Copy-Item $script -Destination "scripts/maintenance/encoding/python/" -Force
        Write-Host "Script Python copié: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script Python non trouvé: $script" -ForegroundColor Yellow
    }
}

# Déplacement des scripts PowerShell
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
        Copy-Item $script -Destination "scripts/maintenance/encoding/powershell/" -Force
        Write-Host "Script PowerShell copié: $script" -ForegroundColor Green
    }
    else {
        Write-Host "Script PowerShell non trouvé: $script" -ForegroundColor Yellow
    }
}

# Création d'un script de lancement rapide
$launchScript = @"
# Script de lancement rapide pour les outils de gestion des caractères accentués

param (
    [Parameter(Mandatory=`$true)]
    [ValidateSet("fix", "import", "remove-duplicates", "list", "delete-all")]
    [string]`$Action
)

`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path

switch (`$Action) {
    "fix" {
        Write-Host "Correction des caractères accentués dans les fichiers JSON..." -ForegroundColor Cyan
        python `$scriptPath/python/fix_all_workflows.py
    }
    "import" {
        Write-Host "Importation des workflows corrigés..." -ForegroundColor Cyan
        & `$scriptPath/powershell/import-fixed-all-workflows.ps1
    }
    "remove-duplicates" {
        Write-Host "Suppression des doublons et des workflows mal encodés..." -ForegroundColor Cyan
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

$launchScript | Out-File -FilePath "scripts/maintenance/encoding/encoding-tools.ps1" -Encoding utf8
Write-Host "Script de lancement rapide créé: scripts/maintenance/encoding/encoding-tools.ps1" -ForegroundColor Green

# Création d'un fichier README pour le répertoire
$readmeContent = @"
# Outils de gestion des caractères accentués français dans n8n

Ce répertoire contient des scripts et des outils pour résoudre les problèmes d'encodage des caractères accentués français dans les workflows n8n.

## Utilisation rapide

Utilisez le script `encoding-tools.ps1` pour lancer rapidement les outils :

```powershell
# Correction des caractères accentués
.\encoding-tools.ps1 -Action fix

# Importation des workflows corrigés
.\encoding-tools.ps1 -Action import

# Suppression des doublons et des workflows mal encodés
.\encoding-tools.ps1 -Action remove-duplicates

# Liste des workflows existants
.\encoding-tools.ps1 -Action list

# Suppression de tous les workflows existants
.\encoding-tools.ps1 -Action delete-all
```

## Structure du répertoire

- **python/** - Scripts Python pour la correction des caractères accentués
  - `fix_all_workflows.py` - Remplace les caractères accentués dans les fichiers JSON
  - `fix_encoding_simple.py` - Version simplifiée du script de correction d'encodage
  - `fix_workflow_names.py` - Se concentre sur la correction des noms des workflows
  - `list_n8n_workflows.py` - Liste les workflows présents dans l'instance n8n
  - `remove_accents.py` - Utilitaire pour remplacer les caractères accentués

- **powershell/** - Scripts PowerShell pour l'interaction avec n8n
  - `import-fixed-all-workflows.ps1` - Importe les workflows corrigés dans n8n
  - `remove-duplicate-workflows.ps1` - Supprime les workflows en double ou mal encodés
  - `delete-all-workflows-auto.ps1` - Supprime tous les workflows existants sans confirmation
  - `list-workflows.ps1` - Liste les workflows existants dans n8n
  - `get-workflows.ps1` - Récupère les détails des workflows via l'API n8n
  - `fix-encoding-utf8.ps1` - Corrige l'encodage des fichiers JSON en UTF-8 avec BOM
  - `fix-workflow-names.ps1` - Corrige les noms des workflows

- **logs/** - Logs des opérations effectuées

## Documentation

Pour plus d'informations, consultez le guide complet : [Guide de gestion des caractères accentués français dans n8n](../../../docs/guides/GUIDE_GESTION_CARACTERES_ACCENTES.md)
"@

$readmeContent | Out-File -FilePath "scripts/maintenance/encoding/README.md" -Encoding utf8
Write-Host "Fichier README créé: scripts/maintenance/encoding/README.md" -ForegroundColor Green

Write-Host "`nOrganisation des outils de gestion des caractères accentués terminée !" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le script de lancement rapide : scripts/maintenance/encoding/encoding-tools.ps1" -ForegroundColor Cyan
