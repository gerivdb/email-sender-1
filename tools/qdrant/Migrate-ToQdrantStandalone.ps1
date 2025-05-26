# Migrate-ToQdrantStandalone.ps1
# Script pour migrer de QDrant Docker vers QDrant standalone

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour migrer un fichier
function Update-QdrantReferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "Fichier non trouvé: $FilePath" -Level Warning
        return $false
    }
    
    Write-Log "Traitement du fichier: $FilePath" -Level Info
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $modified = $false
        
        # Remplacements pour les scripts PowerShell
        if ($FilePath -like "*.ps1") {
            
            # Remplacer les références au script Docker par le script standalone
            $dockerScriptPattern = 'Join-Path.*?"Start-QdrantContainer\.ps1"'
            $standaloneReplacement = 'Join-Path $PSScriptRoot "..\..\tools\qdrant\Start-QdrantStandalone.ps1"'
            if ($content -match $dockerScriptPattern) {
                $content = $content -replace $dockerScriptPattern, $standaloneReplacement
                $modified = $true
                Write-Log "  → Référence au script Docker mise à jour" -Level Info
            }
            
            # Remplacer les appels docker
            $dockerCallPattern = 'docker (run|start|stop).*qdrant'
            if ($content -match $dockerCallPattern) {
                # Pour l'instant, on commente ces lignes
                $content = $content -replace '(\s*)(docker (?:run|start|stop).*qdrant.*)', '$1# MIGRATED: $2'
                $modified = $true
                Write-Log "  → Commandes Docker commentées" -Level Info
            }
            
            # Remplacer les vérifications de conteneur Docker
            $dockerCheckPattern = 'docker ps.*qdrant'
            if ($content -match $dockerCheckPattern) {
                $content = $content -replace '(\s*)(docker ps.*qdrant.*)', '$1# MIGRATED: $2'
                $modified = $true
                Write-Log "  → Vérifications Docker commentées" -Level Info
            }
            
            # Mettre à jour les chemins de données
            $dockerDataPattern = '"projet\\roadmaps\\vectors\\qdrant_data"'
            $standaloneDataPattern = '"..\..\data\qdrant"'
            if ($content -match $dockerDataPattern) {
                $content = $content -replace $dockerDataPattern, $standaloneDataPattern
                $modified = $true
                Write-Log "  → Chemin de données mis à jour" -Level Info
            }
            
            # Ajouter un commentaire de migration en haut du fichier
            if ($modified -and -not ($content -match "# MIGRATED TO QDRANT STANDALONE")) {
                $migrationComment = "# MIGRATED TO QDRANT STANDALONE - $(Get-Date -Format 'yyyy-MM-dd')`n"
                $content = $migrationComment + $content
            }
        }
        
        # Sauvegarder le fichier modifié
        if ($modified) {
            if (-not $DryRun) {
                Set-Content $FilePath $content -Encoding UTF8
                Write-Log "  ✓ Fichier mis à jour: $FilePath" -Level Success
            } else {
                Write-Log "  [DRY RUN] Fichier serait mis à jour: $FilePath" -Level Info
            }
            return $true
        } else {
            Write-Log "  • Aucune modification nécessaire" -Level Info
            return $false
        }
        
    } catch {
        Write-Log "Erreur lors du traitement de $FilePath : $_" -Level Error
        return $false
    }
}

# Fonction pour créer des alias de scripts
function New-StandaloneAliases {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    Write-Log "Création des scripts d'alias pour la compatibilité..." -Level Info
    
    $aliasDir = Join-Path $PSScriptRoot "..\..\development\scripts\roadmap\rag"
    
    # Créer un alias pour Start-QdrantContainer.ps1
    $dockerAliasPath = Join-Path $aliasDir "Start-QdrantContainer.ps1"
    $dockerAliasContent = @"
# MIGRATED TO QDRANT STANDALONE - $(Get-Date -Format 'yyyy-MM-dd')
# Alias de compatibilité pour Start-QdrantContainer.ps1
# Redirige vers le script QDrant standalone

[CmdletBinding()]
param (    [Parameter(Mandatory = $false)]
    [ValidateSet("Start", "Stop", "Status", "Restart")]
    [string]$Action = "Start",
    
    [Parameter(Mandatory = $false)]
    [string]$DataPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Write-Warning "Ce script utilise maintenant QDrant standalone au lieu de Docker."
Write-Host "Redirection vers Start-QdrantStandalone.ps1..." -ForegroundColor Yellow

$standaloneScript = Join-Path $PSScriptRoot "..\..\tools\qdrant\Start-QdrantStandalone.ps1"

if (Test-Path $standaloneScript) {
    if ($Action -eq "Start") {
        & $standaloneScript -Action Start -Background -Force:$Force
    } else {
        & $standaloneScript -Action $Action -Force:$Force
    }
} else {
    Write-Error "Script QDrant standalone non trouvé: $standaloneScript"
    exit 1
}
"@
    
    if (-not $DryRun) {
        # Sauvegarder l'original s'il existe
        if (Test-Path $dockerAliasPath) {
            $backupPath = $dockerAliasPath + ".docker-backup"
            Copy-Item $dockerAliasPath $backupPath -Force
            Write-Log "Sauvegarde créée: $backupPath" -Level Info
        }
        
        Set-Content $dockerAliasPath $dockerAliasContent -Encoding UTF8
        Write-Log "Alias Docker créé: $dockerAliasPath" -Level Success
    } else {
        Write-Log "[DRY RUN] Alias Docker prêt: $dockerAliasPath" -Level Info
    }
}

# Fonction pour mettre à jour les configurations
function Update-Configurations {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    Write-Log "Mise à jour des fichiers de configuration..." -Level Info
    
    $configPatterns = @(
        "..\..\development\scripts\roadmap\rag\config\qdrant\*.ps1",
        "..\..\development\scripts\roadmap\rag\*.ps1",
        "..\..\development\scripts\roadmap\rag\search\*.ps1",
        "..\..\development\scripts\roadmap\rag\metadata\*.ps1"
    )
    
    $totalFiles = 0
    $modifiedFiles = 0
    
    foreach ($pattern in $configPatterns) {
        $fullPattern = Join-Path $PSScriptRoot $pattern
        $files = Get-ChildItem $fullPattern -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            $totalFiles++
            if (Update-QdrantReferences -FilePath $file.FullName -DryRun:$DryRun) {
                $modifiedFiles++
            }
        }
    }
    
    Write-Log "Traitement terminé: $modifiedFiles/$totalFiles fichiers modifiés" -Level Success
}

# Fonction principale
function Main {
    Write-Log "=== Migration QDrant Docker vers Standalone ===" -Level Info
    
    if ($DryRun) {
        Write-Log "MODE DRY RUN - Aucune modification ne sera effectuée" -Level Warning
    }
    
    # Vérifier que QDrant standalone est installé
    $standaloneScript = Join-Path $PSScriptRoot "Start-QdrantStandalone.ps1"
    if (-not (Test-Path $standaloneScript)) {
        Write-Log "QDrant standalone non trouvé. Veuillez d'abord installer QDrant standalone." -Level Error
        return $false
    }
    
    # Vérifier que QDrant standalone fonctionne
    $qdrantExe = Join-Path $PSScriptRoot "qdrant.exe"
    if (-not (Test-Path $qdrantExe)) {
        Write-Log "Exécutable QDrant non trouvé: $qdrantExe" -Level Error
        return $false
    }
    
    Write-Log "QDrant standalone détecté" -Level Success
    
    # Créer les alias de compatibilité
    New-StandaloneAliases -DryRun:$DryRun
    
    # Mettre à jour les fichiers de configuration
    Update-Configurations -DryRun:$DryRun
    
    # Afficher les prochaines étapes
    Write-Log "=== Migration terminée ===" -Level Success
    
    if (-not $DryRun) {
        Write-Log "Prochaines étapes:" -Level Info
        Write-Log "1. Testez QDrant standalone: .\Start-QdrantStandalone.ps1 -Action Status" -Level Info
        Write-Log "2. Démarrez QDrant: .\Start-QdrantStandalone.ps1 -Action Start -Background" -Level Info
        Write-Log "3. Testez vos scripts existants pour vérifier la compatibilité" -Level Info
        Write-Log "4. Les sauvegardes .docker-backup peuvent être supprimées une fois les tests validés" -Level Info
    } else {
        Write-Log "Utilisez -DryRun:`$false pour appliquer les modifications" -Level Info
    }
    
    return $true
}

# Exécuter la fonction principale
$result = Main
exit ([int](!$result))
