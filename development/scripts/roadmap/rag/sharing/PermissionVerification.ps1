<#
.SYNOPSIS
    Module de vérification des permissions pour le partage des vues.

.DESCRIPTION
    Ce module implémente le système de vérification des permissions qui permet
    de vérifier les permissions en temps réel et de journaliser les violations.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de gestion des permissions
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$permissionManagerPath = Join-Path -Path $scriptDir -ChildPath "PermissionManager.ps1"

if (Test-Path -Path $permissionManagerPath) {
    . $permissionManagerPath
}
else {
    throw "Le module PermissionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionManagerPath"
}

# Classe pour représenter le système de vérification des permissions
class PermissionVerification {
    # Propriétés
    [string]$VerificationStorePath
    [string]$LogPath
    [bool]$EnableDebug
    [bool]$EnableRealTimeVerification
    [hashtable]$VerificationCache

    # Constructeur par défaut
    PermissionVerification() {
        $this.VerificationStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"
        $this.LogPath = Join-Path -Path $this.VerificationStorePath -ChildPath "Logs"
        $this.EnableDebug = $false
        $this.EnableRealTimeVerification = $true
        $this.VerificationCache = @{}
    }

    # Constructeur avec paramètres
    PermissionVerification([string]$verificationStorePath, [bool]$enableDebug, [bool]$enableRealTimeVerification) {
        $this.VerificationStorePath = $verificationStorePath
        $this.LogPath = Join-Path -Path $this.VerificationStorePath -ChildPath "Logs"
        $this.EnableDebug = $enableDebug
        $this.EnableRealTimeVerification = $enableRealTimeVerification
        $this.VerificationCache = @{}
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [PermissionVerification] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des vérifications
    [void] InitializeVerificationStore() {
        $this.WriteDebug("Initialisation du stockage des vérifications")
        
        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.VerificationStorePath)) {
                New-Item -Path $this.VerificationStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.VerificationStorePath)")
            }
            
            # Créer le répertoire de logs s'il n'existe pas
            if (-not (Test-Path -Path $this.LogPath)) {
                New-Item -Path $this.LogPath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de logs créé: $($this.LogPath)")
            }
            
            $this.WriteDebug("Initialisation du stockage des vérifications terminée")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des vérifications - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des vérifications - $($_.Exception.Message)"
        }
    }

    # Méthode pour vérifier une permission
    [bool] VerifyPermission([string]$resourceId, [string]$principal, [string]$permission, [string]$action) {
        $this.WriteDebug("Vérification de la permission $permission pour $principal sur la ressource $resourceId pour l'action $action")
        
        try {
            # Initialiser le stockage des vérifications
            $this.InitializeVerificationStore()
            
            # Vérifier si la vérification en temps réel est activée
            if (-not $this.EnableRealTimeVerification) {
                $this.WriteDebug("La vérification en temps réel est désactivée, permission accordée par défaut")
                return $true
            }
            
            # Vérifier si la permission est en cache
            $cacheKey = "$resourceId-$principal-$permission"
            
            if ($this.VerificationCache.ContainsKey($cacheKey)) {
                $cachedResult = $this.VerificationCache[$cacheKey]
                $this.WriteDebug("Résultat en cache: $cachedResult")
                
                # Journaliser l'accès
                $this.LogAccess($resourceId, $principal, $permission, $action, $cachedResult)
                
                return $cachedResult
            }
            
            # Vérifier la permission
            $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
            $hasPermission = $permManager.HasPermission($resourceId, $principal, $permission)
            
            # Mettre en cache le résultat
            $this.VerificationCache[$cacheKey] = $hasPermission
            
            # Journaliser l'accès
            $this.LogAccess($resourceId, $principal, $permission, $action, $hasPermission)
            
            if ($hasPermission) {
                $this.WriteDebug("Permission accordée")
            }
            else {
                $this.WriteDebug("Permission refusée")
                
                # Journaliser la violation
                $this.LogViolation($resourceId, $principal, $permission, $action)
            }
            
            return $hasPermission
        }
        catch {
            $this.WriteDebug("Erreur lors de la vérification de la permission - $($_.Exception.Message)")
            throw "Erreur lors de la vérification de la permission - $($_.Exception.Message)"
        }
    }

    # Méthode pour journaliser un accès
    [void] LogAccess([string]$resourceId, [string]$principal, [string]$permission, [string]$action, [bool]$granted) {
        $this.WriteDebug("Journalisation de l'accès à la ressource $resourceId par $principal")
        
        try {
            # Créer l'objet d'accès
            $access = @{
                ResourceId = $resourceId
                Principal = $principal
                Permission = $permission
                Action = $action
                Granted = $granted
                Timestamp = (Get-Date).ToString('o')
                IpAddress = "127.0.0.1" # À remplacer par l'adresse IP réelle
                UserAgent = "PowerShell" # À remplacer par l'agent utilisateur réel
            }
            
            # Générer le nom du fichier de log
            $date = Get-Date -Format "yyyyMMdd"
            $logFileName = "access_$date.log"
            $logFilePath = Join-Path -Path $this.LogPath -ChildPath $logFileName
            
            # Convertir l'accès en JSON
            $accessJson = $access | ConvertTo-Json -Compress
            
            # Ajouter l'accès au fichier de log
            $accessJson | Out-File -FilePath $logFilePath -Append -Encoding utf8
            
            $this.WriteDebug("Accès journalisé avec succès")
        }
        catch {
            $this.WriteDebug("Erreur lors de la journalisation de l'accès - $($_.Exception.Message)")
            # Ne pas propager l'erreur pour éviter d'interrompre le flux principal
        }
    }

    # Méthode pour journaliser une violation
    [void] LogViolation([string]$resourceId, [string]$principal, [string]$permission, [string]$action) {
        $this.WriteDebug("Journalisation de la violation pour la ressource $resourceId par $principal")
        
        try {
            # Créer l'objet de violation
            $violation = @{
                ResourceId = $resourceId
                Principal = $principal
                Permission = $permission
                Action = $action
                Timestamp = (Get-Date).ToString('o')
                IpAddress = "127.0.0.1" # À remplacer par l'adresse IP réelle
                UserAgent = "PowerShell" # À remplacer par l'agent utilisateur réel
                Severity = "High"
            }
            
            # Générer le nom du fichier de log
            $date = Get-Date -Format "yyyyMMdd"
            $logFileName = "violation_$date.log"
            $logFilePath = Join-Path -Path $this.LogPath -ChildPath $logFileName
            
            # Convertir la violation en JSON
            $violationJson = $violation | ConvertTo-Json -Compress
            
            # Ajouter la violation au fichier de log
            $violationJson | Out-File -FilePath $logFilePath -Append -Encoding utf8
            
            $this.WriteDebug("Violation journalisée avec succès")
        }
        catch {
            $this.WriteDebug("Erreur lors de la journalisation de la violation - $($_.Exception.Message)")
            # Ne pas propager l'erreur pour éviter d'interrompre le flux principal
        }
    }

    # Méthode pour obtenir les accès récents
    [array] GetRecentAccesses([string]$resourceId, [int]$count = 10) {
        $this.WriteDebug("Récupération des $count accès récents pour la ressource $resourceId")
        
        try {
            $accesses = @()
            
            # Vérifier si le répertoire de logs existe
            if (-not (Test-Path -Path $this.LogPath)) {
                $this.WriteDebug("Le répertoire de logs n'existe pas")
                return $accesses
            }
            
            # Récupérer tous les fichiers de log d'accès
            $logFiles = Get-ChildItem -Path $this.LogPath -Filter "access_*.log" | Sort-Object LastWriteTime -Descending
            
            foreach ($file in $logFiles) {
                $fileContent = Get-Content -Path $file.FullName
                
                foreach ($line in $fileContent) {
                    $access = $line | ConvertFrom-Json
                    
                    if ($access.ResourceId -eq $resourceId) {
                        $accesses += $access
                        
                        if ($accesses.Count -ge $count) {
                            break
                        }
                    }
                }
                
                if ($accesses.Count -ge $count) {
                    break
                }
            }
            
            $this.WriteDebug("$($accesses.Count) accès récents récupérés")
            return $accesses
        }
        catch {
            $this.WriteDebug("Erreur lors de la récupération des accès récents - $($_.Exception.Message)")
            throw "Erreur lors de la récupération des accès récents - $($_.Exception.Message)"
        }
    }

    # Méthode pour obtenir les violations récentes
    [array] GetRecentViolations([string]$resourceId, [int]$count = 10) {
        $this.WriteDebug("Récupération des $count violations récentes pour la ressource $resourceId")
        
        try {
            $violations = @()
            
            # Vérifier si le répertoire de logs existe
            if (-not (Test-Path -Path $this.LogPath)) {
                $this.WriteDebug("Le répertoire de logs n'existe pas")
                return $violations
            }
            
            # Récupérer tous les fichiers de log de violations
            $logFiles = Get-ChildItem -Path $this.LogPath -Filter "violation_*.log" | Sort-Object LastWriteTime -Descending
            
            foreach ($file in $logFiles) {
                $fileContent = Get-Content -Path $file.FullName
                
                foreach ($line in $fileContent) {
                    $violation = $line | ConvertFrom-Json
                    
                    if ($violation.ResourceId -eq $resourceId) {
                        $violations += $violation
                        
                        if ($violations.Count -ge $count) {
                            break
                        }
                    }
                }
                
                if ($violations.Count -ge $count) {
                    break
                }
            }
            
            $this.WriteDebug("$($violations.Count) violations récentes récupérées")
            return $violations
        }
        catch {
            $this.WriteDebug("Erreur lors de la récupération des violations récentes - $($_.Exception.Message)")
            throw "Erreur lors de la récupération des violations récentes - $($_.Exception.Message)"
        }
    }

    # Méthode pour vider le cache de vérification
    [void] ClearVerificationCache() {
        $this.WriteDebug("Vidage du cache de vérification")
        $this.VerificationCache = @{}
        $this.WriteDebug("Cache de vérification vidé")
    }
}

# Fonction pour créer un nouveau système de vérification des permissions
function New-PermissionVerification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VerificationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableRealTimeVerification = $true
    )
    
    return [PermissionVerification]::new($VerificationStorePath, $EnableDebug, $EnableRealTimeVerification)
}

# Fonction pour vérifier une permission
function Test-PermissionVerification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $true)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$VerificationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableRealTimeVerification = $true
    )
    
    $verification = New-PermissionVerification -VerificationStorePath $VerificationStorePath -EnableDebug:$EnableDebug -EnableRealTimeVerification $EnableRealTimeVerification
    return $verification.VerifyPermission($ResourceId, $Principal, $Permission, $Action)
}

# Fonction pour obtenir les accès récents
function Get-RecentAccesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$VerificationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $verification = New-PermissionVerification -VerificationStorePath $VerificationStorePath -EnableDebug:$EnableDebug
    return $verification.GetRecentAccesses($ResourceId, $Count)
}

# Fonction pour obtenir les violations récentes
function Get-RecentViolations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$VerificationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $verification = New-PermissionVerification -VerificationStorePath $VerificationStorePath -EnableDebug:$EnableDebug
    return $verification.GetRecentViolations($ResourceId, $Count)
}

# Fonction pour vider le cache de vérification
function Clear-VerificationCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VerificationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\VerificationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $verification = New-PermissionVerification -VerificationStorePath $VerificationStorePath -EnableDebug:$EnableDebug
    $verification.ClearVerificationCache()
}

# Exporter les fonctions
# Export-ModuleMember -Function New-PermissionVerification, Test-PermissionVerification, Get-RecentAccesses, Get-RecentViolations, Clear-VerificationCache
