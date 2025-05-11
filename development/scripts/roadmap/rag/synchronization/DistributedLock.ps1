<#
.SYNOPSIS
    Implémentation de verrous distribués pour la synchronisation entre processus.

.DESCRIPTION
    Ce module fournit une implémentation de verrous distribués basée sur des fichiers
    pour permettre la synchronisation entre différents processus PowerShell.
    Il prend en charge les modes de verrouillage exclusif et partagé, ainsi que
    des mécanismes de timeout et de réessai.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Classe pour représenter un verrou distribué
class DistributedLock {
    # Propriétés
    [string]$ResourceId
    [string]$LockId
    [string]$InstanceId
    [string]$LockFilePath
    [string]$LockMode
    [int]$Timeout
    [int]$RetryCount
    [int]$RetryDelay
    [bool]$IsAcquired
    [datetime]$AcquiredTime
    [datetime]$ExpiryTime
    [string]$LockDirectory
    [bool]$Debug

    # Constructeur
    DistributedLock(
        [string]$ResourceId,
        [string]$InstanceId,
        [string]$LockDirectory,
        [hashtable]$Options
    ) {
        $this.ResourceId = $ResourceId
        $this.InstanceId = $InstanceId
        $this.LockDirectory = $LockDirectory
        $this.LockId = "lock_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
        $this.LockFilePath = Join-Path -Path $LockDirectory -ChildPath "$($this.GetSafeResourceId()).lock"
        $this.LockMode = if ($Options.ContainsKey('Mode')) { $Options.Mode } else { 'exclusive' }
        $this.Timeout = if ($Options.ContainsKey('Timeout')) { $Options.Timeout } else { 30000 }  # 30 secondes par défaut
        $this.RetryCount = if ($Options.ContainsKey('RetryCount')) { $Options.RetryCount } else { 3 }
        $this.RetryDelay = if ($Options.ContainsKey('RetryDelay')) { $Options.RetryDelay } else { 1000 }  # 1 seconde par défaut
        $this.IsAcquired = $false
        $this.AcquiredTime = [datetime]::MinValue
        $this.ExpiryTime = [datetime]::MinValue
        $this.Debug = if ($Options.ContainsKey('Debug')) { $Options.Debug } else { $false }

        # Créer le répertoire de verrous s'il n'existe pas
        if (-not (Test-Path -Path $this.LockDirectory -PathType Container)) {
            New-Item -Path $this.LockDirectory -ItemType Directory -Force | Out-Null
        }
    }

    # Méthode pour obtenir un ID de ressource sécurisé pour les noms de fichiers
    [string] GetSafeResourceId() {
        # Remplacer les caractères non valides dans les noms de fichiers
        $safeId = $this.ResourceId -replace '[\\\/\:\*\?\"\<\>\|]', '_'
        return $safeId
    }

    # Méthode pour acquérir le verrou
    [bool] Acquire() {
        $this.WriteDebug("Tentative d'acquisition du verrou pour la ressource $($this.ResourceId)")

        # Vérifier si le verrou est déjà acquis
        if ($this.IsAcquired) {
            $this.WriteDebug("Le verrou est déjà acquis pour la ressource $($this.ResourceId)")
            return $true
        }

        # Initialiser les variables pour les tentatives
        $attemptsLeft = $this.RetryCount + 1
        $acquired = $false

        while ($attemptsLeft -gt 0 -and -not $acquired) {
            $attemptsLeft--

            try {
                # Vérifier si le fichier de verrou existe
                if (Test-Path -Path $this.LockFilePath) {
                    # Lire le contenu du fichier de verrou
                    $lockContent = Get-Content -Path $this.LockFilePath -Raw -ErrorAction Stop

                    # Analyser le contenu du verrou
                    $lockInfo = $this._ParseLockContent($lockContent)

                    # Vérifier si le verrou est expiré
                    if ($this._IsLockExpired($lockInfo)) {
                        $this.WriteDebug("Verrou expiré trouvé, suppression...")
                        Remove-Item -Path $this.LockFilePath -Force -ErrorAction Stop
                    }
                    # Vérifier si le verrou est détenu par cette instance
                    elseif ($lockInfo.InstanceId -eq $this.InstanceId) {
                        $this.WriteDebug("Verrou déjà détenu par cette instance, renouvellement...")
                        $this._RenewLock()
                        $acquired = $true
                        break
                    }
                    # Vérifier si le mode de verrou est compatible (pour les verrous partagés)
                    elseif ($this.LockMode -eq 'shared' -and $lockInfo.Mode -eq 'shared') {
                        $this.WriteDebug("Verrou partagé compatible trouvé, ajout de cette instance...")
                        $this._AddSharedLock()
                        $acquired = $true
                        break
                    } else {
                        $this.WriteDebug("Verrou détenu par une autre instance, attente...")
                        Start-Sleep -Milliseconds $this.RetryDelay
                        continue
                    }
                }

                # Créer le contenu du verrou
                $lockContent = $this._CreateLockContent()

                # Créer le fichier de verrou
                $lockContent | Out-File -FilePath $this.LockFilePath -Encoding utf8 -ErrorAction Stop

                # Vérifier que le verrou a bien été créé
                if (Test-Path -Path $this.LockFilePath) {
                    $this.IsAcquired = $true
                    $this.AcquiredTime = Get-Date
                    $this.ExpiryTime = $this.AcquiredTime.AddMilliseconds($this.Timeout)
                    $acquired = $true
                    $this.WriteDebug("Verrou acquis pour la ressource $($this.ResourceId)")
                }
            } catch {
                $this.WriteDebug("Erreur lors de l'acquisition du verrou: $_")
                Start-Sleep -Milliseconds $this.RetryDelay
            }
        }

        return $acquired
    }

    # Méthode pour libérer le verrou
    [bool] Release() {
        $this.WriteDebug("Tentative de libération du verrou pour la ressource $($this.ResourceId)")

        # Vérifier si le verrou est acquis
        if (-not $this.IsAcquired) {
            $this.WriteDebug("Le verrou n'est pas acquis pour la ressource $($this.ResourceId)")
            return $true
        }

        try {
            # Vérifier si le fichier de verrou existe
            if (Test-Path -Path $this.LockFilePath) {
                # Lire le contenu du fichier de verrou
                $lockContent = Get-Content -Path $this.LockFilePath -Raw -ErrorAction Stop

                # Analyser le contenu du verrou
                $lockInfo = $this._ParseLockContent($lockContent)

                # Vérifier si le verrou est détenu par cette instance
                if ($lockInfo.InstanceId -eq $this.InstanceId) {
                    # Si c'est un verrou partagé avec plusieurs instances, retirer uniquement cette instance
                    if ($this.LockMode -eq 'shared' -and $lockInfo.SharedInstances -and $lockInfo.SharedInstances.Count -gt 1) {
                        $this.WriteDebug("Libération d'un verrou partagé avec plusieurs instances...")
                        $this._RemoveSharedLock($lockInfo)
                    } else {
                        # Sinon, supprimer complètement le fichier de verrou
                        $this.WriteDebug("Suppression du fichier de verrou...")
                        Remove-Item -Path $this.LockFilePath -Force -ErrorAction Stop
                    }

                    $this.IsAcquired = $false
                    $this.AcquiredTime = [datetime]::MinValue
                    $this.ExpiryTime = [datetime]::MinValue
                    $this.WriteDebug("Verrou libéré pour la ressource $($this.ResourceId)")
                    return $true
                } else {
                    $this.WriteDebug("Le verrou est détenu par une autre instance, impossible de le libérer")
                    return $false
                }
            } else {
                $this.WriteDebug("Le fichier de verrou n'existe pas, considéré comme libéré")
                $this.IsAcquired = $false
                $this.AcquiredTime = [datetime]::MinValue
                $this.ExpiryTime = [datetime]::MinValue
                return $true
            }
        } catch {
            $this.WriteDebug("Erreur lors de la libération du verrou: $_")
            return $false
        }
    }

    # Méthode pour renouveler le verrou
    [bool] Renew() {
        $this.WriteDebug("Tentative de renouvellement du verrou pour la ressource $($this.ResourceId)")

        # Vérifier si le verrou est acquis
        if (-not $this.IsAcquired) {
            $this.WriteDebug("Le verrou n'est pas acquis pour la ressource $($this.ResourceId)")
            return $false
        }

        try {
            return $this._RenewLock()
        } catch {
            $this.WriteDebug("Erreur lors du renouvellement du verrou: $_")
            return $false
        }
    }

    # Méthode privée pour renouveler le verrou
    hidden [bool] _RenewLock() {
        try {
            # Vérifier si le fichier de verrou existe
            if (Test-Path -Path $this.LockFilePath) {
                # Lire le contenu du fichier de verrou
                $lockContent = Get-Content -Path $this.LockFilePath -Raw -ErrorAction Stop

                # Analyser le contenu du verrou
                $lockInfo = $this._ParseLockContent($lockContent)

                # Vérifier si le verrou est détenu par cette instance
                if ($lockInfo.InstanceId -eq $this.InstanceId) {
                    # Mettre à jour les timestamps
                    $now = Get-Date
                    $this.AcquiredTime = $now
                    $this.ExpiryTime = $now.AddMilliseconds($this.Timeout)

                    # Mettre à jour le contenu du verrou
                    $lockInfo.Timestamp = $now.ToString('o')
                    $lockInfo.Expiry = $this.ExpiryTime.ToString('o')

                    # Écrire le contenu mis à jour
                    $updatedContent = $this._SerializeLockInfo($lockInfo)
                    $updatedContent | Out-File -FilePath $this.LockFilePath -Encoding utf8 -Force -ErrorAction Stop

                    $this.WriteDebug("Verrou renouvelé pour la ressource $($this.ResourceId)")
                    return $true
                } else {
                    $this.WriteDebug("Le verrou est détenu par une autre instance, impossible de le renouveler")
                    return $false
                }
            } else {
                $this.WriteDebug("Le fichier de verrou n'existe pas, impossible de le renouveler")
                $this.IsAcquired = $false
                return $false
            }
        } catch {
            $this.WriteDebug("Erreur lors du renouvellement du verrou: $_")
            return $false
        }
    }

    # Méthode privée pour ajouter cette instance à un verrou partagé existant
    hidden [bool] _AddSharedLock() {
        try {
            # Vérifier si le fichier de verrou existe
            if (Test-Path -Path $this.LockFilePath) {
                # Lire le contenu du fichier de verrou
                $lockContent = Get-Content -Path $this.LockFilePath -Raw -ErrorAction Stop

                # Analyser le contenu du verrou
                $lockInfo = $this._ParseLockContent($lockContent)

                # Vérifier si le mode est bien partagé
                if ($lockInfo.Mode -ne 'shared') {
                    $this.WriteDebug("Le verrou existant n'est pas en mode partagé")
                    return $false
                }

                # Mettre à jour les timestamps
                $now = Get-Date
                $this.AcquiredTime = $now
                $this.ExpiryTime = $now.AddMilliseconds($this.Timeout)

                # Ajouter cette instance à la liste des instances partagées
                if (-not $lockInfo.SharedInstances) {
                    $lockInfo.SharedInstances = @()
                }

                # Vérifier si cette instance est déjà dans la liste
                if ($lockInfo.SharedInstances -notcontains $this.InstanceId) {
                    $lockInfo.SharedInstances += $this.InstanceId
                }

                # Mettre à jour le contenu du verrou
                $updatedContent = $this._SerializeLockInfo($lockInfo)
                $updatedContent | Out-File -FilePath $this.LockFilePath -Encoding utf8 -Force -ErrorAction Stop

                $this.IsAcquired = $true
                $this.WriteDebug("Instance ajoutée au verrou partagé pour la ressource $($this.ResourceId)")
                return $true
            } else {
                $this.WriteDebug("Le fichier de verrou n'existe pas, impossible d'ajouter l'instance")
                return $false
            }
        } catch {
            $this.WriteDebug("Erreur lors de l'ajout de l'instance au verrou partagé: $_")
            return $false
        }
    }

    # Méthode privée pour retirer cette instance d'un verrou partagé
    hidden [bool] _RemoveSharedLock($lockInfo) {
        try {
            # Retirer cette instance de la liste des instances partagées
            $lockInfo.SharedInstances = $lockInfo.SharedInstances | Where-Object { $_ -ne $this.InstanceId }

            # Si la liste est vide, supprimer le fichier de verrou
            if ($lockInfo.SharedInstances.Count -eq 0) {
                Remove-Item -Path $this.LockFilePath -Force -ErrorAction Stop
            } else {
                # Sinon, mettre à jour le contenu du verrou
                $updatedContent = $this._SerializeLockInfo($lockInfo)
                $updatedContent | Out-File -FilePath $this.LockFilePath -Encoding utf8 -Force -ErrorAction Stop
            }

            $this.WriteDebug("Instance retirée du verrou partagé pour la ressource $($this.ResourceId)")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors du retrait de l'instance du verrou partagé: $_")
            return $false
        }
    }

    # Méthode privée pour créer le contenu du verrou
    hidden [string] _CreateLockContent() {
        $now = Get-Date
        $expiry = $now.AddMilliseconds($this.Timeout)

        $lockInfo = @{
            ResourceId = $this.ResourceId
            LockId     = $this.LockId
            InstanceId = $this.InstanceId
            Mode       = $this.LockMode
            Timestamp  = $now.ToString('o')
            Expiry     = $expiry.ToString('o')
        }

        # Ajouter la liste des instances partagées si c'est un verrou partagé
        if ($this.LockMode -eq 'shared') {
            $lockInfo.SharedInstances = @($this.InstanceId)
        }

        return $this._SerializeLockInfo($lockInfo)
    }

    # Méthode privée pour analyser le contenu du verrou
    hidden [hashtable] _ParseLockContent([string]$content) {
        try {
            # PowerShell 5.1 n'a pas le paramètre -AsHashtable
            $jsonObject = $content | ConvertFrom-Json
            $hashtable = @{}

            # Convertir manuellement l'objet JSON en hashtable
            $jsonObject.PSObject.Properties | ForEach-Object {
                $hashtable[$_.Name] = $_.Value
            }

            return $hashtable
        } catch {
            $this.WriteDebug("Erreur lors de l'analyse du contenu du verrou: $_")
            return @{
                ResourceId = $this.ResourceId
                InstanceId = "unknown"
                Mode       = "exclusive"
                Timestamp  = (Get-Date).ToString('o')
                Expiry     = (Get-Date).ToString('o')
            }
        }
    }

    # Méthode privée pour sérialiser les informations du verrou
    hidden [string] _SerializeLockInfo([hashtable]$lockInfo) {
        return $lockInfo | ConvertTo-Json
    }

    # Méthode privée pour vérifier si un verrou est expiré
    hidden [bool] _IsLockExpired([hashtable]$lockInfo) {
        try {
            $expiry = [datetime]::Parse($lockInfo.Expiry)
            return (Get-Date) -gt $expiry
        } catch {
            $this.WriteDebug("Erreur lors de la vérification de l'expiration du verrou: $_")
            return $true  # Considérer comme expiré en cas d'erreur
        }
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[DistributedLock] $message" -ForegroundColor Cyan
        }
    }
}

# Fonction pour créer un nouveau verrou distribué
function New-DistributedLock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$InstanceId,

        [Parameter(Mandatory = $false)]
        [string]$LockDirectory = (Join-Path -Path $env:TEMP -ChildPath "DistributedLocks"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("exclusive", "shared")]
        [string]$Mode = "exclusive",

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30000,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelay = 1000,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $options = @{
        Mode       = $Mode
        Timeout    = $Timeout
        RetryCount = $RetryCount
        RetryDelay = $RetryDelay
        Debug      = $EnableDebug.IsPresent
    }

    return [DistributedLock]::new($ResourceId, $InstanceId, $LockDirectory, $options)
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module
# Export-ModuleMember -Function New-DistributedLock
