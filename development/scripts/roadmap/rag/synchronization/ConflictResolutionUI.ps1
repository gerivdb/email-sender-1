<#
.SYNOPSIS
    Interface utilisateur pour la résolution manuelle des conflits.

.DESCRIPTION
    Ce module fournit une interface utilisateur pour la résolution manuelle des conflits
    détectés lors de la synchronisation des données. Il permet d'afficher les différences
    entre les versions en conflit, de sélectionner les éléments à conserver et de valider
    les choix de l'utilisateur.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de gestion des conflits
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$conflictManagerPath = Join-Path -Path $scriptDir -ChildPath "ConflictManager.ps1"

if (Test-Path -Path $conflictManagerPath) {
    . $conflictManagerPath
} else {
    throw "Le module ConflictManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictManagerPath"
}

# Classe pour représenter une différence entre deux états
class StateDifference {
    [string]$PropertyPath
    [object]$LocalValue
    [object]$RemoteValue
    [bool]$IsConflict
    [bool]$UseLocalValue
    [bool]$UseRemoteValue
    [bool]$UseMergedValue
    [object]$MergedValue

    # Constructeur
    StateDifference(
        [string]$propertyPath,
        [object]$localValue,
        [object]$remoteValue
    ) {
        $this.PropertyPath = $propertyPath
        $this.LocalValue = $localValue
        $this.RemoteValue = $remoteValue
        $this.IsConflict = $this._DetermineIfConflict()
        $this.UseLocalValue = $false
        $this.UseRemoteValue = $false
        $this.UseMergedValue = $false
        $this.MergedValue = $null
    }

    # Méthode pour déterminer si la différence est un conflit
    hidden [bool] _DetermineIfConflict() {
        # Si l'une des valeurs est $null et l'autre non, c'est un conflit
        if (($null -eq $this.LocalValue -and $null -ne $this.RemoteValue) -or
            ($null -ne $this.LocalValue -and $null -eq $this.RemoteValue)) {
            return $true
        }

        # Si les deux valeurs sont $null, ce n'est pas un conflit
        if ($null -eq $this.LocalValue -and $null -eq $this.RemoteValue) {
            return $false
        }

        # Si les valeurs sont différentes, c'est un conflit
        return -not ($this.LocalValue -eq $this.RemoteValue)
    }

    # Méthode pour obtenir une représentation textuelle de la différence
    [string] ToString() {
        $localValueStr = if ($null -eq $this.LocalValue) { "null" } else { $this.LocalValue.ToString() }
        $remoteValueStr = if ($null -eq $this.RemoteValue) { "null" } else { $this.RemoteValue.ToString() }

        return "Propriété: $($this.PropertyPath), Local: $localValueStr, Distant: $remoteValueStr, Conflit: $($this.IsConflict)"
    }
}

# Classe pour l'interface de résolution manuelle des conflits
class ConflictResolutionUI {
    # Propriétés
    [Conflict]$Conflict
    [System.Collections.Generic.List[StateDifference]]$Differences
    [hashtable]$ResolvedState
    [bool]$IsResolved
    [bool]$UseConsoleUI
    [bool]$Debug

    # Constructeur
    ConflictResolutionUI(
        [Conflict]$conflict,
        [hashtable]$options
    ) {
        $this.Conflict = $conflict
        $this.Differences = [System.Collections.Generic.List[StateDifference]]::new()
        $this.ResolvedState = @{}
        $this.IsResolved = $false
        $this.UseConsoleUI = if ($options.ContainsKey('UseConsoleUI')) {
            $options.UseConsoleUI
        } else {
            $true
        }
        $this.Debug = if ($options.ContainsKey('Debug')) {
            $options.Debug
        } else {
            $false
        }

        # Analyser les différences entre les états local et distant
        $this._AnalyzeDifferences($this.Conflict.LocalState, $this.Conflict.RemoteState)

        $this.WriteDebug("Interface de résolution manuelle créée pour le conflit $($conflict.ConflictId)")
    }

    # Méthode pour analyser les différences entre deux états
    hidden [void] _AnalyzeDifferences(
        [hashtable]$localState,
        [hashtable]$remoteState
    ) {
        $this._AnalyzeDifferencesInternal($localState, $remoteState, "")
    }

    # Méthode interne pour analyser les différences entre deux états
    hidden [void] _AnalyzeDifferencesInternal(
        [hashtable]$localState,
        [hashtable]$remoteState,
        [string]$parentPath
    ) {
        # Analyser toutes les clés de l'état local
        foreach ($key in $localState.Keys) {
            $propertyPath = if ([string]::IsNullOrEmpty($parentPath)) { $key } else { "$parentPath.$key" }

            if ($remoteState.ContainsKey($key)) {
                # Si la clé existe dans les deux états
                $localValue = $localState[$key]
                $remoteValue = $remoteState[$key]

                # Si les deux valeurs sont des hashtables, analyser récursivement
                if ($localValue -is [hashtable] -and $remoteValue -is [hashtable]) {
                    $this._AnalyzeDifferencesInternal($localValue, $remoteValue, $propertyPath)
                } else {
                    # Sinon, ajouter une différence
                    $difference = [StateDifference]::new($propertyPath, $localValue, $remoteValue)
                    $this.Differences.Add($difference)
                }
            } else {
                # Si la clé n'existe que dans l'état local
                $difference = [StateDifference]::new($propertyPath, $localState[$key], $null)
                $this.Differences.Add($difference)
            }
        }

        # Analyser les clés qui n'existent que dans l'état distant
        foreach ($key in $remoteState.Keys) {
            if (-not $localState.ContainsKey($key)) {
                $propertyPath = if ([string]::IsNullOrEmpty($parentPath)) { $key } else { "$parentPath.$key" }
                $difference = [StateDifference]::new($propertyPath, $null, $remoteState[$key])
                $this.Differences.Add($difference)
            }
        }
    }

    # Méthode pour afficher les différences
    [void] ShowDifferences() {
        if ($this.UseConsoleUI) {
            $this._ShowDifferencesConsole()
        } else {
            $this._ShowDifferencesGUI()
        }
    }

    # Méthode pour afficher les différences dans la console
    hidden [void] _ShowDifferencesConsole() {
        Write-Host "Différences pour le conflit $($this.Conflict.ConflictId) de type $($this.Conflict.Type)" -ForegroundColor Cyan
        Write-Host "Ressource: $($this.Conflict.ResourceId)" -ForegroundColor Cyan
        Write-Host "Description: $($this.Conflict.Description)" -ForegroundColor Cyan
        Write-Host "Sévérité: $($this.Conflict.Severity)" -ForegroundColor Cyan
        Write-Host ""

        $index = 1
        foreach ($difference in $this.Differences) {
            $conflictStr = if ($difference.IsConflict) { "[CONFLIT]" } else { "" }
            Write-Host "$index. $conflictStr Propriété: $($difference.PropertyPath)" -ForegroundColor Yellow

            $localValueStr = if ($null -eq $difference.LocalValue) { "null" } else { $difference.LocalValue.ToString() }
            $remoteValueStr = if ($null -eq $difference.RemoteValue) { "null" } else { $difference.RemoteValue.ToString() }

            Write-Host "   Local:   $localValueStr" -ForegroundColor Green
            Write-Host "   Distant: $remoteValueStr" -ForegroundColor Magenta
            Write-Host ""

            $index++
        }
    }

    # Méthode pour afficher les différences dans une interface graphique
    hidden [void] _ShowDifferencesGUI() {
        # Cette méthode devrait être implémentée en fonction des besoins spécifiques
        # Pour l'exemple, nous allons simplement afficher un message
        Write-Host "L'interface graphique n'est pas encore implémentée. Utilisez l'interface console." -ForegroundColor Yellow
        $this._ShowDifferencesConsole()
    }

    # Méthode pour résoudre manuellement le conflit
    [hashtable] ResolveManually() {
        if ($this.UseConsoleUI) {
            return $this._ResolveManuallyConsole()
        } else {
            return $this._ResolveManuallyGUI()
        }
    }

    # Méthode pour résoudre manuellement le conflit dans la console
    hidden [hashtable] _ResolveManuallyConsole() {
        $this.ShowDifferences()

        Write-Host "Résolution manuelle du conflit $($this.Conflict.ConflictId)" -ForegroundColor Cyan
        Write-Host "Pour chaque différence, choisissez la valeur à conserver:" -ForegroundColor Cyan
        Write-Host "L: Valeur locale, R: Valeur distante, M: Fusionner, S: Ignorer" -ForegroundColor Cyan
        Write-Host ""

        $index = 1
        foreach ($difference in $this.Differences) {
            $conflictStr = if ($difference.IsConflict) { "[CONFLIT]" } else { "" }
            Write-Host "$index. $conflictStr Propriété: $($difference.PropertyPath)" -ForegroundColor Yellow

            $localValueStr = if ($null -eq $difference.LocalValue) { "null" } else { $difference.LocalValue.ToString() }
            $remoteValueStr = if ($null -eq $difference.RemoteValue) { "null" } else { $difference.RemoteValue.ToString() }

            Write-Host "   Local:   $localValueStr" -ForegroundColor Green
            Write-Host "   Distant: $remoteValueStr" -ForegroundColor Magenta

            $choice = $null
            do {
                $choice = Read-Host "Choisissez [L/R/M/S]"
                $choice = $choice.ToUpper()
            } while ($choice -notin @("L", "R", "M", "S"))

            switch ($choice) {
                "L" {
                    $difference.UseLocalValue = $true
                    $difference.UseRemoteValue = $false
                    $difference.UseMergedValue = $false
                    Write-Host "   Valeur locale sélectionnée" -ForegroundColor Green
                }
                "R" {
                    $difference.UseLocalValue = $false
                    $difference.UseRemoteValue = $true
                    $difference.UseMergedValue = $false
                    Write-Host "   Valeur distante sélectionnée" -ForegroundColor Magenta
                }
                "M" {
                    $difference.UseLocalValue = $false
                    $difference.UseRemoteValue = $false
                    $difference.UseMergedValue = $true
                    $difference.MergedValue = $this._MergeValues($difference.LocalValue, $difference.RemoteValue)
                    Write-Host "   Valeurs fusionnées" -ForegroundColor Yellow
                }
                "S" {
                    $difference.UseLocalValue = $false
                    $difference.UseRemoteValue = $false
                    $difference.UseMergedValue = $false
                    Write-Host "   Différence ignorée" -ForegroundColor Gray
                }
            }

            Write-Host ""
            $index++
        }

        # Construire l'état résolu
        $this._BuildResolvedState()

        Write-Host "Résolution manuelle terminée" -ForegroundColor Cyan

        return $this.ResolvedState
    }

    # Méthode pour résoudre manuellement le conflit dans une interface graphique
    hidden [hashtable] _ResolveManuallyGUI() {
        # Cette méthode devrait être implémentée en fonction des besoins spécifiques
        # Pour l'exemple, nous allons simplement afficher un message
        Write-Host "L'interface graphique n'est pas encore implémentée. Utilisez l'interface console." -ForegroundColor Yellow
        return $this._ResolveManuallyConsole()
    }

    # Méthode pour fusionner deux valeurs
    hidden [object] _MergeValues([object]$localValue, [object]$remoteValue) {
        # Si l'une des valeurs est $null, retourner l'autre
        if ($null -eq $localValue) {
            return $remoteValue
        }

        if ($null -eq $remoteValue) {
            return $localValue
        }

        # Si les deux valeurs sont des hashtables, les fusionner
        if ($localValue -is [hashtable] -and $remoteValue -is [hashtable]) {
            $merged = @{}

            # Fusionner les clés communes
            foreach ($key in $localValue.Keys) {
                if ($remoteValue.ContainsKey($key)) {
                    $merged[$key] = $this._MergeValues($localValue[$key], $remoteValue[$key])
                } else {
                    $merged[$key] = $localValue[$key]
                }
            }

            # Ajouter les clés qui n'existent que dans l'état distant
            foreach ($key in $remoteValue.Keys) {
                if (-not $localValue.ContainsKey($key)) {
                    $merged[$key] = $remoteValue[$key]
                }
            }

            return $merged
        }

        # Si les deux valeurs sont des chaînes, les concaténer
        if ($localValue -is [string] -and $remoteValue -is [string]) {
            return "$localValue + $remoteValue"
        }

        # Par défaut, retourner la valeur distante
        return $remoteValue
    }

    # Méthode pour construire l'état résolu
    hidden [void] _BuildResolvedState() {
        $this.ResolvedState = @{}

        foreach ($difference in $this.Differences) {
            $propertyPath = $difference.PropertyPath
            $pathParts = $propertyPath -split "\."

            $currentState = $this.ResolvedState

            # Naviguer dans l'arborescence des propriétés
            for ($i = 0; $i -lt $pathParts.Count - 1; $i++) {
                $part = $pathParts[$i]

                if (-not $currentState.ContainsKey($part)) {
                    $currentState[$part] = @{}
                }

                $currentState = $currentState[$part]
            }

            # Ajouter la valeur à l'état résolu
            $lastPart = $pathParts[-1]

            if ($difference.UseLocalValue) {
                $currentState[$lastPart] = $difference.LocalValue
            } elseif ($difference.UseRemoteValue) {
                $currentState[$lastPart] = $difference.RemoteValue
            } elseif ($difference.UseMergedValue) {
                $currentState[$lastPart] = $difference.MergedValue
            }
        }

        $this.IsResolved = $true
    }

    # Méthode pour valider les choix de l'utilisateur
    [bool] ValidateChoices() {
        # Vérifier que toutes les différences en conflit ont été résolues
        $unresolvedConflicts = $this.Differences | Where-Object {
            $_.IsConflict -and -not ($_.UseLocalValue -or $_.UseRemoteValue -or $_.UseMergedValue)
        }

        if ($unresolvedConflicts.Count -gt 0) {
            Write-Host "Il reste des conflits non résolus:" -ForegroundColor Red

            foreach ($conflict in $unresolvedConflicts) {
                Write-Host "- $($conflict.PropertyPath)" -ForegroundColor Red
            }

            return $false
        }

        return $true
    }

    # Méthode pour appliquer la résolution au conflit
    [bool] ApplyResolution() {
        if (-not $this.IsResolved) {
            $this.WriteDebug("Impossible d'appliquer la résolution: le conflit n'est pas résolu")
            return $false
        }

        $this.Conflict.MergedState = $this.ResolvedState
        $this.Conflict.IsResolved = $true
        $this.Conflict.AppliedStrategy = [ResolutionStrategy]::MergeManual

        $this.WriteDebug("Résolution appliquée au conflit $($this.Conflict.ConflictId)")

        return $true
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[ConflictResolutionUI] $message" -ForegroundColor Blue
        }
    }
}

# Fonction pour créer une nouvelle interface de résolution manuelle des conflits
function New-ConflictResolutionUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Conflict]$Conflict,

        [Parameter(Mandatory = $false)]
        [switch]$UseConsoleUI,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $options = @{
        UseConsoleUI = $UseConsoleUI.IsPresent
        Debug        = $EnableDebug.IsPresent
    }

    return [ConflictResolutionUI]::new($Conflict, $options)
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module
# Export-ModuleMember -Function New-ConflictResolutionUI
