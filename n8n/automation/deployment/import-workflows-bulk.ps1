<#
.SYNOPSIS
    Script d'importation en masse des workflows n8n.

.DESCRIPTION
    Ce script importe en masse les workflows n8n depuis des fichiers JSON.
    Il utilise le traitement parallèle pour accélérer l'importation de grands volumes de workflows.

.PARAMETER SourceFolder
    Dossier contenant les workflows à importer (par défaut: n8n/core/workflows/local).

.PARAMETER TargetFolder
    Dossier de destination pour les workflows importés (par défaut: n8n/data/.n8n/workflows).

.PARAMETER Method
    Méthode d'importation à utiliser (API ou CLI, par défaut: CLI).

.PARAMETER ApiKey
    API Key à utiliser pour l'importation via API. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Hostname
    Hôte n8n pour l'importation via API (par défaut: localhost).

.PARAMETER Port
    Port n8n pour l'importation via API (par défaut: 5678).

.PARAMETER Protocol
    Protocole pour l'importation via API (http ou https) (par défaut: http).

.PARAMETER Tags
    Tags à ajouter aux workflows importés (séparés par des virgules).

.PARAMETER Active
    Indique si les workflows importés doivent être activés (par défaut: $true).

.PARAMETER Force
    Force l'importation même si le workflow existe déjà (par défaut: $false).

.PARAMETER LogFile
    Fichier de log pour l'importation (par défaut: n8n/logs/import-workflows-bulk.log).

.PARAMETER Recursive
    Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true).

.PARAMETER BackupFolder
    Dossier de sauvegarde pour les workflows existants avant importation (par défaut: n8n/data/.n8n/workflows/backup).

.PARAMETER MaxConcurrent
    Nombre maximum d'importations simultanées (par défaut: 5).

.PARAMETER BatchSize
    Taille des lots pour l'importation en masse (par défaut: 10).

.EXAMPLE
    .\import-workflows-bulk.ps1 -SourceFolder "path/to/workflows" -Method "API" -MaxConcurrent 10 -BatchSize 20

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$SourceFolder = "n8n/core/workflows/local",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("API", "CLI")]
    [string]$Method = "CLI",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$Tags = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$Active = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/import-workflows-bulk.log",
    
    [Parameter(Mandatory=$false)]
    [bool]$Recursive = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder = "n8n/data/.n8n/workflows/backup",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrent = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$BatchSize = 10
)

# Importer les fonctions des parties précédentes
. "$PSScriptRoot\import-workflows-auto-part1.ps1"
. "$PSScriptRoot\import-workflows-auto-part2.ps1"

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Log "=== Importation en masse des workflows n8n ===" -Level "INFO"
Write-Log "Dossier source: $SourceFolder" -Level "INFO"
Write-Log "Dossier cible: $TargetFolder" -Level "INFO"
Write-Log "Méthode d'importation: $Method" -Level "INFO"
Write-Log "Tags: $Tags" -Level "INFO"
Write-Log "Activation: $Active" -Level "INFO"
Write-Log "Force: $Force" -Level "INFO"
Write-Log "Récursif: $Recursive" -Level "INFO"
Write-Log "Dossier de sauvegarde: $BackupFolder" -Level "INFO"
Write-Log "Fichier de log: $LogFile" -Level "INFO"
Write-Log "Nombre maximum d'importations simultanées: $MaxConcurrent" -Level "INFO"
Write-Log "Taille des lots: $BatchSize" -Level "INFO"

# Récupérer l'API Key si nécessaire
if ($Method -eq "API" -and [string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "Aucune API Key trouvée. L'importation via API échouera." -Level "ERROR"
        exit 1
    } else {
        Write-Log "API Key récupérée depuis la configuration." -Level "INFO"
    }
}

# Construire l'URL de l'API si nécessaire
$ApiUrl = ""
if ($Method -eq "API") {
    $ApiUrl = "$Protocol`://$Hostname`:$Port/api/v1/workflows/import"
    Write-Log "URL de l'API: $ApiUrl" -Level "INFO"
}

# Vérifier si le dossier source existe
if (-not (Test-Path -Path $SourceFolder)) {
    Write-Log "Le dossier source n'existe pas: $SourceFolder" -Level "ERROR"
    exit 1
}

# Obtenir la liste des fichiers à importer
$searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
$files = Get-ChildItem -Path $SourceFolder -Filter "*.json" -File -Recurse:$Recursive

if ($files.Count -eq 0) {
    Write-Log "Aucun fichier JSON trouvé dans le dossier source: $SourceFolder" -Level "WARNING"
    exit 0
}

Write-Log "Nombre de fichiers à importer: $($files.Count)" -Level "INFO"

# Créer le dossier cible s'il n'existe pas
if (-not (Test-Path -Path $TargetFolder)) {
    New-Item -Path $TargetFolder -ItemType Directory -Force | Out-Null
}

# Créer le dossier de sauvegarde s'il n'existe pas
if (-not (Test-Path -Path $BackupFolder)) {
    New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
}

# Diviser les fichiers en lots
$batches = @()
$currentBatch = @()
$batchCount = 0

foreach ($file in $files) {
    $currentBatch += $file
    
    if ($currentBatch.Count -ge $BatchSize) {
        $batches += ,@($currentBatch)
        $currentBatch = @()
        $batchCount++
    }
}

# Ajouter le dernier lot s'il n'est pas vide
if ($currentBatch.Count -gt 0) {
    $batches += ,@($currentBatch)
    $batchCount++
}

Write-Log "Nombre de lots: $batchCount" -Level "INFO"

# Fonction pour importer un lot de workflows
function Import-WorkflowBatch {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Files,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ApiUrl = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$TargetFolder = "",
        
        [Parameter(Mandatory=$false)]
        [string]$BackupFolder = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Force = $false
    )
    
    $results = @{
        Success = 0
        Failure = 0
        Total = $Files.Count
    }
    
    foreach ($file in $Files) {
        # Valider le fichier
        if (-not (Test-WorkflowFile -FilePath $file.FullName)) {
            $results.Failure++
            continue
        }
        
        # Importer le workflow selon la méthode spécifiée
        $importSuccess = $false
        
        if ($Method -eq "API") {
            # Importer via l'API
            $response = Import-WorkflowViaApi -FilePath $file.FullName -ApiUrl $ApiUrl -ApiKey $ApiKey -Tags $Tags -Active $Active
            $importSuccess = ($null -ne $response)
        } else {
            # Importer via la CLI
            $importSuccess = Import-WorkflowViaCli -FilePath $file.FullName -Tags $Tags -Active $Active
        }
        
        # Copier le fichier vers le dossier cible si l'importation a réussi
        if ($importSuccess) {
            $copySuccess = Copy-WorkflowToTarget -SourcePath $file.FullName -TargetFolder $TargetFolder -Force $Force -BackupFolder $BackupFolder
            
            if ($copySuccess) {
                $results.Success++
            } else {
                $results.Failure++
            }
        } else {
            $results.Failure++
        }
    }
    
    return $results
}

# Initialiser les compteurs
$totalSuccess = 0
$totalFailure = 0

# Traiter les lots en parallèle
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7+ : utiliser ForEach-Object -Parallel
    Write-Log "Utilisation de ForEach-Object -Parallel pour le traitement parallèle" -Level "INFO"
    
    $batchResults = $batches | ForEach-Object -ThrottleLimit $MaxConcurrent -Parallel {
        # Importer les fonctions nécessaires dans le runspace
        . "$using:PSScriptRoot\import-workflows-auto-part1.ps1"
        . "$using:PSScriptRoot\import-workflows-auto-part2.ps1"
        
        # Importer le lot
        $result = Import-WorkflowBatch -Files $_ -Method $using:Method -ApiKey $using:ApiKey -ApiUrl $using:ApiUrl -Tags $using:Tags -Active $using:Active -TargetFolder $using:TargetFolder -BackupFolder $using:BackupFolder -Force $using:Force
        
        # Afficher le résultat du lot
        Write-Log "Lot traité: $($_.Count) fichiers, $($result.Success) succès, $($result.Failure) échecs" -Level "INFO"
        
        return $result
    }
} else {
    # PowerShell 5.1 : utiliser des jobs
    Write-Log "Utilisation de jobs pour le traitement parallèle" -Level "INFO"
    
    # Créer les jobs
    $jobs = @()
    
    foreach ($batch in $batches) {
        $jobScript = {
            param($batch, $scriptRoot, $method, $apiKey, $apiUrl, $tags, $active, $targetFolder, $backupFolder, $force)
            
            # Importer les fonctions nécessaires
            . "$scriptRoot\import-workflows-auto-part1.ps1"
            . "$scriptRoot\import-workflows-auto-part2.ps1"
            
            # Importer le lot
            $result = Import-WorkflowBatch -Files $batch -Method $method -ApiKey $apiKey -ApiUrl $apiUrl -Tags $tags -Active $active -TargetFolder $targetFolder -BackupFolder $backupFolder -Force $force
            
            return $result
        }
        
        $job = Start-Job -ScriptBlock $jobScript -ArgumentList $batch, $PSScriptRoot, $Method, $ApiKey, $ApiUrl, $Tags, $Active, $TargetFolder, $BackupFolder, $Force
        $jobs += $job
        
        # Limiter le nombre de jobs simultanés
        while ((Get-Job -State Running).Count -ge $MaxConcurrent) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Attendre que tous les jobs soient terminés
    Write-Log "Attente de la fin des jobs..." -Level "INFO"
    $jobs | Wait-Job | Out-Null
    
    # Récupérer les résultats
    $batchResults = $jobs | Receive-Job
    
    # Nettoyer les jobs
    $jobs | Remove-Job
}

# Calculer les résultats globaux
foreach ($result in $batchResults) {
    $totalSuccess += $result.Success
    $totalFailure += $result.Failure
}

$totalCount = $files.Count
$successRate = if ($totalCount -gt 0) { [Math]::Round(($totalSuccess / $totalCount) * 100, 2) } else { 0 }

# Afficher le résumé
Write-Log "=== Résumé de l'importation en masse ===" -Level "INFO"
Write-Log "Total des fichiers: $totalCount" -Level "INFO"
Write-Log "Succès: $totalSuccess" -Level "SUCCESS"
Write-Log "Échecs: $totalFailure" -Level "ERROR"
Write-Log "Taux de réussite: $successRate%" -Level "INFO"

# Retourner les résultats
return @{
    Success = $totalSuccess
    Failure = $totalFailure
    Total = $totalCount
    SuccessRate = $successRate
}
