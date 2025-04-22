<#
.SYNOPSIS
    Script d'importation automatique des workflows n8n (Partie 1 : Fonctions de base et paramètres).

.DESCRIPTION
    Ce script contient les fonctions de base et les paramètres pour l'importation automatique des workflows n8n.
    Il est conçu pour être utilisé avec les autres parties du script d'importation.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Paramètres communs à toutes les parties du script
$script:CommonParams = @{
    SourceFolder = "n8n/core/workflows/local"
    TargetFolder = "n8n/data/.n8n/workflows"
    Method = "CLI"
    ApiKey = ""
    Hostname = "localhost"
    Port = 5678
    Protocol = "http"
    Tags = ""
    Active = $true
    Force = $false
    LogFile = "n8n/logs/import-workflows.log"
    Recursive = $true
    BackupFolder = "n8n/data/.n8n/workflows/backup"
    MaxConcurrent = 5
}

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier de log
    Add-Content -Path $script:CommonParams.LogFile -Value $logMessage
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour récupérer l'API Key depuis les fichiers de configuration
function Get-ApiKeyFromConfig {
    # Essayer de récupérer l'API Key depuis le fichier de configuration
    $configFile = Join-Path -Path (Get-Location) -ChildPath "n8n/core/n8n-config.json"
    if (Test-Path -Path $configFile) {
        try {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            if ($config.security -and $config.security.apiKey -and $config.security.apiKey.value) {
                return $config.security.apiKey.value
            }
        } catch {
            Write-Log "Erreur lors de la lecture du fichier de configuration: $_" -Level "ERROR"
        }
    }
    
    # Essayer de récupérer l'API Key depuis le fichier .env
    $envFile = Join-Path -Path (Get-Location) -ChildPath "n8n/.env"
    if (Test-Path -Path $envFile) {
        try {
            $envContent = Get-Content -Path $envFile
            foreach ($line in $envContent) {
                if ($line -match "^N8N_API_KEY=(.+)$") {
                    return $matches[1]
                }
            }
        } catch {
            Write-Log "Erreur lors de la lecture du fichier .env: $_" -Level "ERROR"
        }
    }
    
    return ""
}

# Fonction pour valider un fichier de workflow
function Test-WorkflowFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier n'existe pas: $FilePath" -Level "ERROR"
            return $false
        }
        
        # Vérifier si le fichier est un JSON valide
        $content = Get-Content -Path $FilePath -Raw
        $null = $content | ConvertFrom-Json
        
        # Vérifier si le fichier contient les propriétés requises d'un workflow n8n
        $workflow = $content | ConvertFrom-Json
        if (-not $workflow.name -or -not $workflow.nodes) {
            Write-Log "Le fichier ne semble pas être un workflow n8n valide: $FilePath" -Level "WARNING"
            return $false
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de la validation du fichier de workflow: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour sauvegarder un workflow existant
function Backup-Workflow {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupFolder
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            return $true
        }
        
        # Créer le dossier de sauvegarde s'il n'existe pas
        if (-not (Test-Path -Path $BackupFolder)) {
            New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
        }
        
        # Générer un nom de fichier unique pour la sauvegarde
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFileName = "$timestamp-$fileName"
        $backupFilePath = Join-Path -Path $BackupFolder -ChildPath $backupFileName
        
        # Copier le fichier
        Copy-Item -Path $FilePath -Destination $backupFilePath -Force
        
        Write-Log "Workflow sauvegardé: $FilePath -> $backupFilePath" -Level "INFO"
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde du workflow: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour copier un workflow vers le dossier cible
function Copy-WorkflowToTarget {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder,
        
        [Parameter(Mandatory=$false)]
        [bool]$Force = $false,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupFolder = ""
    )
    
    try {
        # Vérifier si le fichier source existe
        if (-not (Test-Path -Path $SourcePath)) {
            Write-Log "Le fichier source n'existe pas: $SourcePath" -Level "ERROR"
            return $false
        }
        
        # Créer le dossier cible s'il n'existe pas
        if (-not (Test-Path -Path $TargetFolder)) {
            New-Item -Path $TargetFolder -ItemType Directory -Force | Out-Null
        }
        
        # Générer le chemin cible
        $fileName = [System.IO.Path]::GetFileName($SourcePath)
        $targetPath = Join-Path -Path $TargetFolder -ChildPath $fileName
        
        # Vérifier si le fichier cible existe déjà
        if (Test-Path -Path $targetPath) {
            # Sauvegarder le fichier existant
            if (-not (Backup-Workflow -FilePath $targetPath -BackupFolder $BackupFolder)) {
                Write-Log "Échec de la sauvegarde du workflow existant: $targetPath" -Level "ERROR"
                return $false
            }
            
            # Supprimer le fichier existant si Force est spécifié
            if ($Force) {
                Remove-Item -Path $targetPath -Force
            } else {
                Write-Log "Le fichier cible existe déjà: $targetPath. Utilisez -Force pour le remplacer." -Level "WARNING"
                return $false
            }
        }
        
        # Copier le fichier
        Copy-Item -Path $SourcePath -Destination $targetPath -Force
        
        Write-Log "Workflow copié: $SourcePath -> $targetPath" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la copie du workflow: $_" -Level "ERROR"
        return $false
    }
}

# Exporter les fonctions et variables pour les autres parties du script
Export-ModuleMember -Function Write-Log, Get-ApiKeyFromConfig, Test-WorkflowFile, Backup-Workflow, Copy-WorkflowToTarget -Variable CommonParams
