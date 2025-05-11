<#
.SYNOPSIS
    Gestionnaire de restauration pour les états synchronisés.

.DESCRIPTION
    Ce module fournit des fonctionnalités pour restaurer des états précédents
    de manière sélective ou complète, avec gestion des conflits et validation
    de cohérence.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$conflictManagerPath = Join-Path -Path $scriptDir -ChildPath "ConflictManager.ps1"
$synchronizationManagerPath = Join-Path -Path $scriptDir -ChildPath "SynchronizationManager.ps1"

if (Test-Path -Path $conflictManagerPath) {
    . $conflictManagerPath
} else {
    throw "Le module ConflictManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictManagerPath"
}

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
} else {
    throw "Le module SynchronizationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $synchronizationManagerPath"
}

# Classe pour gérer les opérations de restauration
class RestoreManager {
    # Propriétés
    [string]$InstanceId
    [SynchronizationManager]$SyncManager
    [hashtable]$RestoreHistory
    [string]$BackupPath
    [bool]$EnableAutoBackup
    [bool]$Debug

    # Constructeur
    RestoreManager(
        [string]$instanceId,
        [SynchronizationManager]$syncManager,
        [hashtable]$options
    ) {
        $this.InstanceId = $instanceId
        $this.SyncManager = $syncManager
        $this.RestoreHistory = @{}

        # Options par défaut
        $this.BackupPath = if ($options.ContainsKey('BackupPath')) {
            $options.BackupPath
        } else {
            Join-Path -Path $env:TEMP -ChildPath "RestoreBackups_$instanceId"
        }

        $this.EnableAutoBackup = if ($options.ContainsKey('EnableAutoBackup')) {
            $options.EnableAutoBackup
        } else {
            $true
        }

        $this.Debug = if ($options.ContainsKey('Debug')) {
            $options.Debug
        } else {
            $false
        }

        # Créer le répertoire de sauvegarde s'il n'existe pas
        if (-not (Test-Path -Path $this.BackupPath)) {
            New-Item -Path $this.BackupPath -ItemType Directory -Force | Out-Null
        }

        $this.WriteDebug("RestoreManager initialisé pour l'instance $instanceId")
    }

    # Méthode pour créer une sauvegarde avant restauration
    [string] CreateBackup([string]$resourceId, [string]$description) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupId = "$($resourceId)_$timestamp"
        $backupFilePath = Join-Path -Path $this.BackupPath -ChildPath "$backupId.json"

        try {
            # Créer le répertoire de sauvegarde s'il n'existe pas
            $backupDir = Split-Path -Path $backupFilePath -Parent
            if (-not (Test-Path -Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }

            # Obtenir l'état actuel de la ressource
            $currentState = $this.SyncManager.GetResourceState($resourceId)

            if ($null -eq $currentState) {
                $this.WriteDebug("Impossible de créer une sauvegarde pour $resourceId : état non trouvé")
                return $null
            }

            # Faire une copie profonde de l'état actuel
            $stateCopy = $this.CloneHashtable($currentState)

            # Créer l'objet de sauvegarde
            $backupObject = @{
                BackupId    = $backupId
                ResourceId  = $resourceId
                Timestamp   = (Get-Date).ToString('o')
                Description = $description
                State       = $stateCopy
            }

            # Sauvegarder l'état
            $backupJson = ConvertTo-Json -InputObject $backupObject -Depth 10
            Set-Content -Path $backupFilePath -Value $backupJson -Encoding UTF8

            # Vérifier que le fichier a bien été créé
            if (-not (Test-Path -Path $backupFilePath)) {
                $this.WriteDebug("Échec de la création du fichier de sauvegarde pour $resourceId")
                return $null
            }

            # Ajouter à l'historique
            $this.RestoreHistory[$backupId] = @{
                BackupId    = $backupId
                ResourceId  = $resourceId
                Timestamp   = (Get-Date)
                Description = $description
                FilePath    = $backupFilePath
            }

            $this.WriteDebug("Sauvegarde créée pour $resourceId avec ID $backupId")

            return $backupId
        } catch {
            $this.WriteDebug("Erreur lors de la création de la sauvegarde pour $resourceId : $_")
            return $null
        }
    }

    # Méthode pour restaurer sélectivement des éléments
    [bool] RestoreSelective(
        [string]$resourceId,
        [string]$backupId,
        [string[]]$propertyPaths,
        [hashtable]$options
    ) {
        # Vérifier si la sauvegarde existe
        $backupFilePath = Join-Path -Path $this.BackupPath -ChildPath "$backupId.json"

        if (-not (Test-Path -Path $backupFilePath)) {
            $this.WriteDebug("Impossible de restaurer $resourceId : sauvegarde $backupId non trouvée")
            return $false
        }

        # Charger la sauvegarde
        $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json
        $backupState = $this.ConvertPSObjectToHashtable($backupContent.State)

        # Obtenir l'état actuel
        $currentState = $this.SyncManager.GetResourceState($resourceId)

        if ($null -eq $currentState) {
            $this.WriteDebug("Impossible de restaurer $resourceId : état actuel non trouvé")
            return $false
        }

        # Créer une sauvegarde avant restauration si activé
        if ($this.EnableAutoBackup) {
            $this.CreateBackup($resourceId, "Sauvegarde automatique avant restauration sélective")
        }

        # Créer l'état restauré
        $restoredState = $this.CloneHashtable($currentState)

        # Restaurer les propriétés sélectionnées
        foreach ($propertyPath in $propertyPaths) {
            $pathParts = $propertyPath -split "\."

            # Extraire la valeur de la sauvegarde
            $backupValue = $this.GetValueFromPath($backupState, $pathParts)

            if ($null -ne $backupValue) {
                # Mettre à jour l'état restauré
                $this.SetValueAtPath($restoredState, $pathParts, $backupValue)
                $this.WriteDebug("Propriété $propertyPath restaurée pour $resourceId")
            } else {
                $this.WriteDebug("Propriété $propertyPath non trouvée dans la sauvegarde pour $resourceId")
            }
        }

        # Vérifier la cohérence de l'état restauré
        $isValid = $this.ValidateRestoredState($restoredState, $options)

        if (-not $isValid) {
            $this.WriteDebug("Validation de l'état restauré échouée pour $resourceId")
            return $false
        }

        # Appliquer la restauration
        $result = $this.SyncManager.UpdateResourceState($resourceId, $restoredState)

        if ($result) {
            $this.WriteDebug("Restauration sélective réussie pour $resourceId")
        } else {
            $this.WriteDebug("Échec de la restauration sélective pour $resourceId")
        }

        return $result
    }

    # Méthode pour restaurer complètement un état
    [bool] RestoreFull(
        [string]$resourceId,
        [string]$backupId,
        [hashtable]$options
    ) {
        # Vérifier si la sauvegarde existe
        $backupFilePath = Join-Path -Path $this.BackupPath -ChildPath "$backupId.json"

        if (-not (Test-Path -Path $backupFilePath)) {
            $this.WriteDebug("Impossible de restaurer $resourceId : sauvegarde $backupId non trouvée")
            return $false
        }

        # Créer une sauvegarde avant restauration si activé
        if ($this.EnableAutoBackup -and -not ($options.ContainsKey('SkipBackup') -and $options.SkipBackup)) {
            $this.CreateBackup($resourceId, "Sauvegarde automatique avant restauration complète")
        }

        try {
            # Charger la sauvegarde
            $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json

            # Vérifier que le contenu de la sauvegarde est valide
            if ($null -eq $backupContent -or $null -eq $backupContent.State) {
                $this.WriteDebug("Contenu de sauvegarde invalide pour $resourceId")
                return $false
            }

            # Convertir l'état de la sauvegarde en hashtable
            $backupState = $this.ConvertPSObjectToHashtable($backupContent.State)

            # Vérifier que l'état de la sauvegarde est valide
            if ($null -eq $backupState -or $backupState.Count -eq 0) {
                $this.WriteDebug("État de sauvegarde vide ou invalide pour $resourceId")
                return $false
            }

            # Vérifier la cohérence de l'état restauré
            $isValid = $this.ValidateRestoredState($backupState, $options)

            if (-not $isValid) {
                $this.WriteDebug("Validation de l'état restauré échouée pour $resourceId")
                return $false
            }

            # Appliquer la restauration
            $result = $this.SyncManager.UpdateResourceState($resourceId, $backupState)

            if ($result) {
                $this.WriteDebug("Restauration complète réussie pour $resourceId")
            } else {
                $this.WriteDebug("Échec de la restauration complète pour $resourceId")
            }

            return $result
        } catch {
            $this.WriteDebug("Erreur lors de la restauration complète pour $resourceId : $_")
            return $false
        }
    }

    # Méthode pour prévisualiser les effets d'une restauration
    [hashtable] PreviewRestore(
        [string]$resourceId,
        [string]$backupId,
        [string[]]$propertyPaths
    ) {
        # Vérifier si la sauvegarde existe
        $backupFilePath = Join-Path -Path $this.BackupPath -ChildPath "$backupId.json"

        if (-not (Test-Path -Path $backupFilePath)) {
            $this.WriteDebug("Impossible de prévisualiser la restauration : sauvegarde $backupId non trouvée")
            return @{
                Success     = $false
                Message     = "Sauvegarde non trouvée"
                Differences = @()
            }
        }

        # Charger la sauvegarde
        $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json
        $backupState = $this.ConvertPSObjectToHashtable($backupContent.State)

        # Obtenir l'état actuel
        $currentState = $this.SyncManager.GetResourceState($resourceId)

        if ($null -eq $currentState) {
            $this.WriteDebug("Impossible de prévisualiser la restauration : état actuel non trouvé")
            return @{
                Success     = $false
                Message     = "État actuel non trouvé"
                Differences = @()
            }
        }

        # Analyser les différences
        $differences = @()

        if ($propertyPaths.Count -eq 0) {
            # Restauration complète, comparer tous les éléments
            $differences = $this.CompareTwoStates($currentState, $backupState)
        } else {
            # Restauration sélective, comparer uniquement les propriétés spécifiées
            foreach ($propertyPath in $propertyPaths) {
                $pathParts = $propertyPath -split "\."

                $currentValue = $this.GetValueFromPath($currentState, $pathParts)
                $backupValue = $this.GetValueFromPath($backupState, $pathParts)

                $differences += @{
                    PropertyPath = $propertyPath
                    CurrentValue = $currentValue
                    BackupValue  = $backupValue
                    HasChanged   = -not $this.AreValuesEqual($currentValue, $backupValue)
                }
            }
        }

        return @{
            Success     = $true
            Message     = "Prévisualisation générée"
            Differences = $differences
            BackupInfo  = @{
                BackupId    = $backupId
                Timestamp   = $backupContent.Timestamp
                Description = $backupContent.Description
            }
        }
    }

    # Méthode pour annuler une restauration
    [bool] UndoRestore([string]$resourceId) {
        # Rechercher la dernière sauvegarde automatique
        $autoBackups = $this.RestoreHistory.Values |
            Where-Object { $_.ResourceId -eq $resourceId -and $_.Description -like "Sauvegarde automatique avant restauration*" } |
            Sort-Object -Property Timestamp -Descending

        if ($autoBackups.Count -eq 0) {
            $this.WriteDebug("Impossible d'annuler la restauration : aucune sauvegarde automatique trouvée pour $resourceId")
            return $false
        }

        $lastAutoBackup = $autoBackups[0]

        # Restaurer à partir de la dernière sauvegarde automatique
        return $this.RestoreFull($resourceId, $lastAutoBackup.BackupId, @{
                SkipBackup = $true  # Éviter une boucle infinie de sauvegardes
            })
    }

    # Méthode pour obtenir l'historique des restaurations
    [array] GetRestoreHistory([string]$resourceId) {
        if ([string]::IsNullOrEmpty($resourceId)) {
            return $this.RestoreHistory.Values | Sort-Object -Property Timestamp -Descending
        } else {
            return $this.RestoreHistory.Values |
                Where-Object { $_.ResourceId -eq $resourceId } |
                Sort-Object -Property Timestamp -Descending
        }
    }

    # Méthode pour valider l'état restauré
    hidden [bool] ValidateRestoredState([hashtable]$state, [hashtable]$options) {
        # Validation de base : vérifier que l'état n'est pas vide
        if ($null -eq $state -or $state.Count -eq 0) {
            $this.WriteDebug("Validation échouée : état vide")
            return $false
        }

        # Validation personnalisée si fournie
        if ($options.ContainsKey('ValidateFunction') -and $options.ValidateFunction -is [scriptblock]) {
            $validationResult = & $options.ValidateFunction $state

            if (-not $validationResult) {
                $this.WriteDebug("Validation personnalisée échouée")
                return $false
            }
        }

        return $true
    }

    # Méthode pour comparer deux états
    hidden [array] CompareTwoStates([hashtable]$state1, [hashtable]$state2, [string]$parentPath = "") {
        $differences = @()

        # Parcourir toutes les clés de l'état 1
        foreach ($key in $state1.Keys) {
            $propertyPath = if ([string]::IsNullOrEmpty($parentPath)) { $key } else { "$parentPath.$key" }

            if ($state2.ContainsKey($key)) {
                $value1 = $state1[$key]
                $value2 = $state2[$key]

                if ($value1 -is [hashtable] -and $value2 -is [hashtable]) {
                    # Récursion pour les hashtables imbriquées
                    $differences += $this.CompareTwoStates($value1, $value2, $propertyPath)
                } else {
                    # Comparer les valeurs
                    $differences += @{
                        PropertyPath = $propertyPath
                        Value1       = $value1
                        Value2       = $value2
                        HasChanged   = -not $this.AreValuesEqual($value1, $value2)
                    }
                }
            } else {
                # Clé présente dans l'état 1 mais pas dans l'état 2
                $differences += @{
                    PropertyPath = $propertyPath
                    Value1       = $state1[$key]
                    Value2       = $null
                    HasChanged   = $true
                }
            }
        }

        # Parcourir les clés qui sont uniquement dans l'état 2
        foreach ($key in $state2.Keys) {
            if (-not $state1.ContainsKey($key)) {
                $propertyPath = if ([string]::IsNullOrEmpty($parentPath)) { $key } else { "$parentPath.$key" }

                $differences += @{
                    PropertyPath = $propertyPath
                    Value1       = $null
                    Value2       = $state2[$key]
                    HasChanged   = $true
                }
            }
        }

        return $differences
    }

    # Méthode pour vérifier si deux valeurs sont égales
    hidden [bool] AreValuesEqual($value1, $value2) {
        # Si les deux valeurs sont null, elles sont égales
        if ($null -eq $value1 -and $null -eq $value2) {
            return $true
        }

        # Si une seule valeur est null, elles sont différentes
        if ($null -eq $value1 -or $null -eq $value2) {
            return $false
        }

        # Si les deux valeurs sont des hashtables, comparer récursivement
        if ($value1 -is [hashtable] -and $value2 -is [hashtable]) {
            # Vérifier si les clés sont identiques
            $keys1 = $value1.Keys | Sort-Object
            $keys2 = $value2.Keys | Sort-Object

            if (-not $this.AreArraysEqual($keys1, $keys2)) {
                return $false
            }

            # Comparer chaque valeur
            foreach ($key in $keys1) {
                if (-not $this.AreValuesEqual($value1[$key], $value2[$key])) {
                    return $false
                }
            }

            return $true
        }

        # Si les deux valeurs sont des tableaux, comparer les éléments
        if ($value1 -is [array] -and $value2 -is [array]) {
            return $this.AreArraysEqual($value1, $value2)
        }

        # Sinon, comparer directement
        return $value1 -eq $value2
    }

    # Méthode pour vérifier si deux tableaux sont égaux
    hidden [bool] AreArraysEqual($array1, $array2) {
        if ($array1.Count -ne $array2.Count) {
            return $false
        }

        for ($i = 0; $i -lt $array1.Count; $i++) {
            if (-not $this.AreValuesEqual($array1[$i], $array2[$i])) {
                return $false
            }
        }

        return $true
    }

    # Méthode pour obtenir une valeur à partir d'un chemin
    hidden [object] GetValueFromPath([hashtable]$state, [string[]]$pathParts) {
        $currentValue = $state

        foreach ($part in $pathParts) {
            if ($currentValue -is [hashtable] -and $currentValue.ContainsKey($part)) {
                $currentValue = $currentValue[$part]
            } else {
                return $null
            }
        }

        return $currentValue
    }

    # Méthode pour définir une valeur à un chemin spécifique
    hidden [void] SetValueAtPath([hashtable]$state, [string[]]$pathParts, [object]$value) {
        $current = $state

        # Naviguer jusqu'au parent du nœud cible
        for ($i = 0; $i -lt $pathParts.Count - 1; $i++) {
            $part = $pathParts[$i]

            if (-not $current.ContainsKey($part)) {
                $current[$part] = @{}
            }

            $current = $current[$part]

            # Si ce n'est pas une hashtable, on ne peut pas continuer
            if (-not ($current -is [hashtable])) {
                $current = @{}
            }
        }

        # Définir la valeur sur le dernier nœud
        $lastPart = $pathParts[-1]

        # Si la valeur est un tableau ou une hashtable, faire une copie profonde
        if ($value -is [array]) {
            $current[$lastPart] = $value.Clone()
        } elseif ($value -is [hashtable]) {
            $current[$lastPart] = $this.CloneHashtable($value)
        } else {
            $current[$lastPart] = $value
        }
    }

    # Méthode pour cloner une hashtable
    hidden [hashtable] CloneHashtable([hashtable]$original) {
        $clone = @{}

        foreach ($key in $original.Keys) {
            $value = $original[$key]

            if ($value -is [hashtable]) {
                $clone[$key] = $this.CloneHashtable($value)
            } elseif ($value -is [array]) {
                $clone[$key] = $value.Clone()
            } else {
                $clone[$key] = $value
            }
        }

        return $clone
    }

    # Méthode pour convertir un PSObject en hashtable
    hidden [hashtable] ConvertPSObjectToHashtable([PSCustomObject]$object) {
        $hashtable = @{}

        foreach ($property in $object.PSObject.Properties) {
            $value = $property.Value

            if ($value -is [PSCustomObject]) {
                $hashtable[$property.Name] = $this.ConvertPSObjectToHashtable($value)
            } elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                $list = @()
                foreach ($item in $value) {
                    if ($item -is [PSCustomObject]) {
                        $list += $this.ConvertPSObjectToHashtable($item)
                    } else {
                        $list += $item
                    }
                }
                $hashtable[$property.Name] = $list
            } else {
                $hashtable[$property.Name] = $value
            }
        }

        return $hashtable
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[RestoreManager] $message" -ForegroundColor Cyan
        }
    }
}

# Fonction pour créer un nouveau gestionnaire de restauration
function New-RestoreManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstanceId,

        [Parameter(Mandatory = $true)]
        [SynchronizationManager]$SyncManager,

        [Parameter(Mandatory = $false)]
        [string]$BackupPath,

        [Parameter(Mandatory = $false)]
        [switch]$EnableAutoBackup,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $options = @{}

    if ($PSBoundParameters.ContainsKey('BackupPath')) {
        $options['BackupPath'] = $BackupPath
    }

    $options['EnableAutoBackup'] = $EnableAutoBackup.IsPresent
    $options['Debug'] = $EnableDebug.IsPresent

    return [RestoreManager]::new($InstanceId, $SyncManager, $options)
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module
# Export-ModuleMember -Function New-RestoreManager
