<#
.SYNOPSIS
    Script de nettoyage des fichiers temporaires n8n.

.DESCRIPTION
    Ce script nettoie les fichiers temporaires créés par n8n, comme les fichiers de cache,
    les fichiers temporaires d'exécution et les fichiers de verrouillage obsolètes.

.PARAMETER N8nRootFolder
    Dossier racine de n8n (par défaut: n8n).

.PARAMETER MaxTempAgeDays
    Âge maximal des fichiers temporaires en jours avant suppression (par défaut: 7).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\cleanup-temp.ps1
    Nettoie les fichiers temporaires avec les paramètres par défaut.

.EXAMPLE
    .\cleanup-temp.ps1 -N8nRootFolder "C:\n8n" -MaxTempAgeDays 14
    Nettoie les fichiers temporaires dans le dossier spécifié avec un âge maximal de 14 jours.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$N8nRootFolder = "n8n",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxTempAgeDays = 7,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
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
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Écrire dans le fichier de log de maintenance
    $logFolder = Join-Path -Path $N8nRootFolder -ChildPath "logs"
    $maintenanceLogFile = Join-Path -Path $logFolder -ChildPath "maintenance.log"
    
    # Créer le dossier de log s'il n'existe pas
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $maintenanceLogFile -Value $logMessage
}

# Fonction pour nettoyer les fichiers temporaires
function Clear-TempFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$N8nRootFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxTempAgeDays
    )
    
    # Vérifier si le dossier racine existe
    if (-not (Test-Path -Path $N8nRootFolder)) {
        Write-Log "Dossier racine n8n non trouvé: $N8nRootFolder" -Level "ERROR"
        return $false
    }
    
    Write-Log "Début du nettoyage des fichiers temporaires" -Level "INFO"
    
    # Calculer la date limite
    $limitDate = (Get-Date).AddDays(-$MaxTempAgeDays)
    
    # Définir les dossiers à nettoyer
    $foldersToClean = @(
        @{
            Path = Join-Path -Path $N8nRootFolder -ChildPath "data/.n8n/cache"
            Pattern = "*.*"
            Description = "Fichiers de cache"
        },
        @{
            Path = Join-Path -Path $N8nRootFolder -ChildPath "data/.n8n/tmp"
            Pattern = "*.*"
            Description = "Fichiers temporaires"
        },
        @{
            Path = Join-Path -Path $N8nRootFolder -ChildPath "data/.n8n/locks"
            Pattern = "*.lock"
            Description = "Fichiers de verrouillage"
        }
    )
    
    $totalCleaned = 0
    $totalSize = 0
    
    # Nettoyer chaque dossier
    foreach ($folder in $foldersToClean) {
        if (Test-Path -Path $folder.Path) {
            Write-Log "Nettoyage des $($folder.Description) dans $($folder.Path)" -Level "INFO"
            
            try {
                # Obtenir les fichiers à supprimer
                $filesToDelete = Get-ChildItem -Path $folder.Path -Filter $folder.Pattern -File | Where-Object { $_.LastWriteTime -lt $limitDate }
                
                if ($filesToDelete.Count -gt 0) {
                    # Calculer la taille totale
                    $folderSize = ($filesToDelete | Measure-Object -Property Length -Sum).Sum
                    $totalSize += $folderSize
                    
                    # Supprimer les fichiers
                    foreach ($file in $filesToDelete) {
                        Remove-Item -Path $file.FullName -Force
                    }
                    
                    $totalCleaned += $filesToDelete.Count
                    
                    Write-Log "$($filesToDelete.Count) $($folder.Description) supprimés ($([Math]::Round($folderSize / 1KB, 2)) KB)" -Level "SUCCESS"
                } else {
                    Write-Log "Aucun $($folder.Description) à supprimer" -Level "INFO"
                }
            } catch {
                Write-Log "Erreur lors du nettoyage des $($folder.Description): $_" -Level "ERROR"
            }
        } else {
            Write-Log "Dossier non trouvé: $($folder.Path)" -Level "WARNING"
        }
    }
    
    Write-Log "Fin du nettoyage des fichiers temporaires" -Level "INFO"
    Write-Log "Total: $totalCleaned fichiers supprimés ($([Math]::Round($totalSize / 1KB, 2)) KB)" -Level "SUCCESS"
    
    return $true
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    # Afficher les paramètres
    Write-Log "Paramètres:" -Level "INFO"
    Write-Log "  N8nRootFolder: $N8nRootFolder" -Level "INFO"
    Write-Log "  MaxTempAgeDays: $MaxTempAgeDays" -Level "INFO"
    
    # Demander confirmation si mode interactif
    if (-not $NoInteractive) {
        $confirmation = Read-Host "Voulez-vous continuer? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur" -Level "WARNING"
            exit
        }
    }
    
    # Nettoyer les fichiers temporaires
    $success = Clear-TempFiles -N8nRootFolder $N8nRootFolder -MaxTempAgeDays $MaxTempAgeDays
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
}

