<#
.SYNOPSIS
    Collecte les métriques d'historique de n8n.

.DESCRIPTION
    Ce script collecte les métriques d'historique de n8n, comme la date du dernier redémarrage,
    le nombre de redémarrages, le nombre d'erreurs et la dernière erreur.

.PARAMETER N8nRootFolder
    Dossier racine de n8n.

.PARAMETER LogFolder
    Dossier contenant les logs de n8n.

.PARAMETER MetricsConfig
    Configuration des métriques à collecter.

.EXAMPLE
    .\dashboard-history-metrics.ps1 -N8nRootFolder "n8n" -LogFolder "n8n/logs"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$N8nRootFolder = "n8n",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFolder = "n8n/logs",
    
    [Parameter(Mandatory=$false)]
    [object]$MetricsConfig = $null
)

# Fonction pour obtenir la date du dernier redémarrage
function Get-LastRestartDate {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder
    )
    
    $logFile = Join-Path -Path $LogFolder -ChildPath "n8n.log"
    
    if (-not (Test-Path -Path $logFile)) {
        return @{
            Success = $false
            LastRestart = $null
            Error = "Fichier de log non trouvé: $logFile"
        }
    }
    
    try {
        # Rechercher les lignes de démarrage dans le fichier de log
        $startLines = Select-String -Path $logFile -Pattern "Starting n8n" -AllMatches
        
        if ($startLines.Count -gt 0) {
            # Obtenir la date de la dernière ligne de démarrage
            $lastStartLine = $startLines[-1]
            $match = $lastStartLine.Line -match "\[(.*?)\]"
            
            if ($matches -and $matches.Count -gt 1) {
                $dateString = $matches[1]
                $lastRestart = [DateTime]::Parse($dateString)
                
                return @{
                    Success = $true
                    LastRestart = $lastRestart
                    Error = $null
                }
            }
        }
        
        # Aucune ligne de démarrage trouvée
        return @{
            Success = $false
            LastRestart = $null
            Error = "Aucune ligne de démarrage trouvée dans le fichier de log"
        }
    } catch {
        return @{
            Success = $false
            LastRestart = $null
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour obtenir le nombre de redémarrages dans les dernières 24 heures
function Get-RestartCount {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$Hours = 24
    )
    
    $logFile = Join-Path -Path $LogFolder -ChildPath "n8n.log"
    
    if (-not (Test-Path -Path $logFile)) {
        return @{
            Success = $false
            RestartCount = 0
            Error = "Fichier de log non trouvé: $logFile"
        }
    }
    
    try {
        # Calculer la date limite
        $limitDate = (Get-Date).AddHours(-$Hours)
        
        # Rechercher les lignes de démarrage dans le fichier de log
        $startLines = Select-String -Path $logFile -Pattern "Starting n8n" -AllMatches
        
        if ($startLines.Count -gt 0) {
            # Compter les redémarrages dans les dernières 24 heures
            $restartCount = 0
            
            foreach ($line in $startLines) {
                $match = $line.Line -match "\[(.*?)\]"
                
                if ($matches -and $matches.Count -gt 1) {
                    $dateString = $matches[1]
                    $restartDate = [DateTime]::Parse($dateString)
                    
                    if ($restartDate -ge $limitDate) {
                        $restartCount++
                    }
                }
            }
            
            return @{
                Success = $true
                RestartCount = $restartCount
                Error = $null
            }
        }
        
        # Aucune ligne de démarrage trouvée
        return @{
            Success = $false
            RestartCount = 0
            Error = "Aucune ligne de démarrage trouvée dans le fichier de log"
        }
    } catch {
        return @{
            Success = $false
            RestartCount = 0
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour obtenir le nombre d'erreurs dans les dernières 24 heures
function Get-ErrorCount {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$Hours = 24
    )
    
    $logFile = Join-Path -Path $LogFolder -ChildPath "n8n.log"
    
    if (-not (Test-Path -Path $logFile)) {
        return @{
            Success = $false
            ErrorCount = 0
            Error = "Fichier de log non trouvé: $logFile"
        }
    }
    
    try {
        # Calculer la date limite
        $limitDate = (Get-Date).AddHours(-$Hours)
        
        # Rechercher les lignes d'erreur dans le fichier de log
        $errorLines = Select-String -Path $logFile -Pattern "ERROR" -AllMatches
        
        if ($errorLines.Count -gt 0) {
            # Compter les erreurs dans les dernières 24 heures
            $errorCount = 0
            
            foreach ($line in $errorLines) {
                $match = $line.Line -match "\[(.*?)\]"
                
                if ($matches -and $matches.Count -gt 1) {
                    $dateString = $matches[1]
                    $errorDate = [DateTime]::Parse($dateString)
                    
                    if ($errorDate -ge $limitDate) {
                        $errorCount++
                    }
                }
            }
            
            return @{
                Success = $true
                ErrorCount = $errorCount
                Error = $null
            }
        }
        
        # Aucune ligne d'erreur trouvée
        return @{
            Success = $true
            ErrorCount = 0
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            ErrorCount = 0
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour obtenir la dernière erreur
function Get-LastError {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder
    )
    
    $logFile = Join-Path -Path $LogFolder -ChildPath "n8n.log"
    
    if (-not (Test-Path -Path $logFile)) {
        return @{
            Success = $false
            LastError = $null
            LastErrorDate = $null
            Error = "Fichier de log non trouvé: $logFile"
        }
    }
    
    try {
        # Rechercher les lignes d'erreur dans le fichier de log
        $errorLines = Select-String -Path $logFile -Pattern "ERROR" -AllMatches
        
        if ($errorLines.Count -gt 0) {
            # Obtenir la dernière ligne d'erreur
            $lastErrorLine = $errorLines[-1]
            $match = $lastErrorLine.Line -match "\[(.*?)\]"
            
            if ($matches -and $matches.Count -gt 1) {
                $dateString = $matches[1]
                $lastErrorDate = [DateTime]::Parse($dateString)
                
                # Extraire le message d'erreur
                $lastError = $lastErrorLine.Line -replace ".*ERROR.*?\] ", ""
                
                return @{
                    Success = $true
                    LastError = $lastError
                    LastErrorDate = $lastErrorDate
                    Error = $null
                }
            }
        }
        
        # Aucune ligne d'erreur trouvée
        return @{
            Success = $true
            LastError = "Aucune erreur trouvée"
            LastErrorDate = $null
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            LastError = $null
            LastErrorDate = $null
            Error = $_.Exception.Message
        }
    }
}

# Fonction principale pour collecter les métriques d'historique
function Get-HistoryMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [string]$N8nRootFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Obtenir la date du dernier redémarrage
    $lastRestartResult = Get-LastRestartDate -LogFolder $LogFolder
    
    # Obtenir le nombre de redémarrages dans les dernières 24 heures
    $restartCountResult = Get-RestartCount -LogFolder $LogFolder
    
    # Obtenir le nombre d'erreurs dans les dernières 24 heures
    $errorCountResult = Get-ErrorCount -LogFolder $LogFolder
    
    # Obtenir la dernière erreur
    $lastErrorResult = Get-LastError -LogFolder $LogFolder
    
    # Préparer les métriques
    $metrics = @{
        LastRestart = @{
            Value = $lastRestartResult.LastRestart
            DisplayValue = if ($lastRestartResult.Success -and $lastRestartResult.LastRestart) {
                $lastRestartResult.LastRestart.ToString("yyyy-MM-dd HH:mm:ss")
            } else { "N/A" }
            Status = if ($lastRestartResult.Success) { "success" } else { "danger" }
            Description = "Date et heure du dernier redémarrage de n8n"
            Details = if ($lastRestartResult.Success) {
                if ($lastRestartResult.LastRestart) {
                    "Il y a " + [Math]::Round(((Get-Date) - $lastRestartResult.LastRestart).TotalHours, 1) + " heures"
                } else {
                    "Aucun redémarrage trouvé"
                }
            } else { "Erreur: $($lastRestartResult.Error)" }
        }
        RestartCount = @{
            Value = if ($restartCountResult.Success) { $restartCountResult.RestartCount } else { 0 }
            DisplayValue = if ($restartCountResult.Success) { $restartCountResult.RestartCount.ToString() } else { "N/A" }
            Status = if ($restartCountResult.Success) {
                if ($restartCountResult.RestartCount -eq 0) { "success" }
                elseif ($restartCountResult.RestartCount -lt 3) { "warning" }
                else { "danger" }
            } else { "danger" }
            Description = "Nombre de redémarrages de n8n dans les dernières 24 heures"
            Details = if ($restartCountResult.Success) {
                "Basé sur les logs dans $LogFolder"
            } else { "Erreur: $($restartCountResult.Error)" }
        }
        ErrorCount = @{
            Value = if ($errorCountResult.Success) { $errorCountResult.ErrorCount } else { 0 }
            DisplayValue = if ($errorCountResult.Success) { $errorCountResult.ErrorCount.ToString() } else { "N/A" }
            Status = if ($errorCountResult.Success) {
                if ($errorCountResult.ErrorCount -eq 0) { "success" }
                elseif ($errorCountResult.ErrorCount -lt 5) { "warning" }
                else { "danger" }
            } else { "danger" }
            Description = "Nombre d'erreurs dans les logs de n8n dans les dernières 24 heures"
            Details = if ($errorCountResult.Success) {
                "Basé sur les logs dans $LogFolder"
            } else { "Erreur: $($errorCountResult.Error)" }
        }
        LastError = @{
            Value = if ($lastErrorResult.Success) { $lastErrorResult.LastError } else { $null }
            DisplayValue = if ($lastErrorResult.Success -and $lastErrorResult.LastErrorDate) {
                "$($lastErrorResult.LastErrorDate.ToString("yyyy-MM-dd HH:mm:ss")): $($lastErrorResult.LastError)"
            } elseif ($lastErrorResult.Success) {
                $lastErrorResult.LastError
            } else { "N/A" }
            Status = if ($lastErrorResult.Success) {
                if ($lastErrorResult.LastErrorDate -eq $null) { "success" }
                elseif (((Get-Date) - $lastErrorResult.LastErrorDate).TotalHours -gt 24) { "success" }
                else { "danger" }
            } else { "danger" }
            Description = "Date, heure et message de la dernière erreur dans les logs de n8n"
            Details = if ($lastErrorResult.Success) {
                if ($lastErrorResult.LastErrorDate) {
                    "Il y a " + [Math]::Round(((Get-Date) - $lastErrorResult.LastErrorDate).TotalHours, 1) + " heures"
                } else {
                    "Aucune erreur trouvée"
                }
            } else { "Erreur: $($lastErrorResult.Error)" }
        }
    }
    
    # Retourner les métriques
    return @{
        Metrics = $metrics
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les métriques
if ($MyInvocation.InvocationName -ne ".") {
    Get-HistoryMetrics -N8nRootFolder $N8nRootFolder -LogFolder $LogFolder -MetricsConfig $MetricsConfig
}
