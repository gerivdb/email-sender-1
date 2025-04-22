<#
.SYNOPSIS
    Script d'importation automatique des workflows n8n.

.DESCRIPTION
    Ce script importe automatiquement les workflows n8n depuis des fichiers JSON.
    Il peut utiliser l'API REST ou la CLI n8n selon la configuration.

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
    Fichier de log pour l'importation (par défaut: n8n/logs/import-workflows.log).

.PARAMETER Recursive
    Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true).

.PARAMETER BackupFolder
    Dossier de sauvegarde pour les workflows existants avant importation (par défaut: n8n/data/.n8n/workflows/backup).

.PARAMETER MaxConcurrent
    Nombre maximum d'importations simultanées (par défaut: 5).

.EXAMPLE
    .\import-workflows-auto.ps1 -SourceFolder "path/to/workflows" -Method "API" -Tags "imported,auto" -Active $true

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
    [string]$LogFile = "n8n/logs/import-workflows.log",
    
    [Parameter(Mandatory=$false)]
    [bool]$Recursive = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder = "n8n/data/.n8n/workflows/backup",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrent = 5
)

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
    Add-Content -Path $LogFile -Value $logMessage
    
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

# Fonction pour importer un workflow via l'API
function Import-WorkflowViaApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier n'existe pas: $FilePath" -Level "ERROR"
            return $null
        }
        
        # Lire le contenu du fichier
        $workflowJson = Get-Content -Path $FilePath -Raw
        
        # Convertir le JSON en objet
        $workflow = $workflowJson | ConvertFrom-Json
        
        # Préparer les données pour l'importation
        $importData = @{
            workflowData = $workflow
            tags = if ([string]::IsNullOrEmpty($Tags)) { @() } else { $Tags.Split(",") }
            active = $Active
        }
        
        # Convertir les données en JSON
        $importDataJson = $importData | ConvertTo-Json -Depth 10
        
        # Préparer les en-têtes
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
            "X-N8N-API-KEY" = $ApiKey
        }
        
        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $headers -Body $importDataJson
        
        return $response
    } catch {
        Write-Log "Erreur lors de l'importation du workflow via API: $_" -Level "ERROR"
        
        # Afficher des informations supplémentaires sur l'erreur
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Log "Code d'état HTTP: $statusCode ($statusDescription)" -Level "ERROR"
            
            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                
                if (-not [string]::IsNullOrEmpty($responseBody)) {
                    Write-Log "Corps de la réponse: $responseBody" -Level "ERROR"
                }
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }
        
        return $null
    }
}

# Fonction pour importer un workflow via la CLI
function Import-WorkflowViaCli {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier n'existe pas: $FilePath" -Level "ERROR"
            return $false
        }
        
        # Préparer les arguments
        $arguments = @("import:workflow", "--file", $FilePath)
        
        if (-not [string]::IsNullOrEmpty($Tags)) {
            $arguments += "--tags"
            $arguments += $Tags
        }
        
        if ($Active) {
            $arguments += "--active"
        }
        
        # Exécuter la commande
        $process = Start-Process -FilePath "npx" -ArgumentList (@("n8n") + $arguments) -NoNewWindow -PassThru -Wait
        
        # Vérifier le code de sortie
        if ($process.ExitCode -eq 0) {
            return $true
        } else {
            Write-Log "Erreur lors de l'importation du workflow via CLI. Code de sortie: $($process.ExitCode)" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'importation du workflow via CLI: $_" -Level "ERROR"
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
        [string]$TargetFolder
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

# Fonction principale pour importer les workflows
function Import-Workflows {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder,
        
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
        [bool]$Recursive = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupFolder = ""
    )
    
    # Vérifier si le dossier source existe
    if (-not (Test-Path -Path $SourceFolder)) {
        Write-Log "Le dossier source n'existe pas: $SourceFolder" -Level "ERROR"
        return @{
            Success = 0
            Failure = 0
            Total = 0
            SuccessRate = 0
        }
    }
    
    # Obtenir la liste des fichiers à importer
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = Get-ChildItem -Path $SourceFolder -Filter "*.json" -File -Recurse:$Recursive
    
    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier JSON trouvé dans le dossier source: $SourceFolder" -Level "WARNING"
        return @{
            Success = 0
            Failure = 0
            Total = 0
            SuccessRate = 0
        }
    }
    
    Write-Log "Nombre de fichiers à importer: $($files.Count)" -Level "INFO"
    
    # Initialiser les compteurs
    $successCount = 0
    $failureCount = 0
    
    # Importer chaque fichier
    foreach ($file in $files) {
        Write-Log "Traitement du fichier: $($file.FullName)" -Level "INFO"
        
        # Valider le fichier
        if (-not (Test-WorkflowFile -FilePath $file.FullName)) {
            Write-Log "Le fichier n'est pas un workflow n8n valide: $($file.FullName)" -Level "ERROR"
            $failureCount++
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
            $copySuccess = Copy-WorkflowToTarget -SourcePath $file.FullName -TargetFolder $TargetFolder
            
            if ($copySuccess) {
                $successCount++
                Write-Log "Workflow importé avec succès: $($file.Name)" -Level "SUCCESS"
            } else {
                $failureCount++
                Write-Log "Échec de la copie du workflow: $($file.Name)" -Level "ERROR"
            }
        } else {
            $failureCount++
            Write-Log "Échec de l'importation du workflow: $($file.Name)" -Level "ERROR"
        }
    }
    
    # Calculer le taux de réussite
    $totalCount = $files.Count
    $successRate = if ($totalCount -gt 0) { [Math]::Round(($successCount / $totalCount) * 100, 2) } else { 0 }
    
    # Retourner les résultats
    return @{
        Success = $successCount
        Failure = $failureCount
        Total = $totalCount
        SuccessRate = $successRate
    }
}

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Log "=== Importation automatique des workflows n8n ===" -Level "INFO"
Write-Log "Dossier source: $SourceFolder" -Level "INFO"
Write-Log "Dossier cible: $TargetFolder" -Level "INFO"
Write-Log "Méthode d'importation: $Method" -Level "INFO"
Write-Log "Tags: $Tags" -Level "INFO"
Write-Log "Activation: $Active" -Level "INFO"
Write-Log "Force: $Force" -Level "INFO"
Write-Log "Récursif: $Recursive" -Level "INFO"
Write-Log "Dossier de sauvegarde: $BackupFolder" -Level "INFO"
Write-Log "Fichier de log: $LogFile" -Level "INFO"

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

# Importer les workflows
$results = Import-Workflows -SourceFolder $SourceFolder -TargetFolder $TargetFolder -Method $Method -ApiKey $ApiKey -ApiUrl $ApiUrl -Tags $Tags -Active $Active -Recursive $Recursive -BackupFolder $BackupFolder

# Afficher le résumé
Write-Log "=== Résumé de l'importation ===" -Level "INFO"
Write-Log "Total des fichiers: $($results.Total)" -Level "INFO"
Write-Log "Succès: $($results.Success)" -Level "SUCCESS"
Write-Log "Échecs: $($results.Failure)" -Level "ERROR"
Write-Log "Taux de réussite: $($results.SuccessRate)%" -Level "INFO"

# Retourner les résultats
return $results
