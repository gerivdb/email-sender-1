<#
.SYNOPSIS
    Script de test pour le gestionnaire de conflits.

.DESCRIPTION
    Ce script teste le fonctionnement du gestionnaire de conflits, notamment la détection
    des conflits, l'analyse des conflits de données et les stratégies de résolution.

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

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $colors = @{
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "ConflictManagerTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour tester la détection des conflits
function Test-ConflictDetection {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test de détection des conflits" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de conflits
    $options = @{
        ConflictLogPath      = $testDir
        EnableAutoResolution = $false
        EnableNotifications  = $true
        Debug                = $true
    }

    $conflictManager = [ConflictManager]::new("instance_test", $options)

    Write-TestMessage "Gestionnaire de conflits créé" -Level "Info"

    # Test 1: Détecter un conflit d'écriture concurrent
    Write-TestMessage "Test 1: Détection d'un conflit d'écriture concurrent" -Level "Info"

    $localState = @{
        Version   = "1.0"
        Content   = "Contenu local"
        Timestamp = (Get-Date).AddMinutes(-5).ToString('o')
    }

    $remoteState = @{
        Version   = "1.1"
        Content   = "Contenu distant"
        Timestamp = (Get-Date).ToString('o')
    }

    $conflict = $conflictManager.DetectConflict("resource1", [ConflictType]::WriteWrite, $localState, $remoteState)

    if ($null -ne $conflict) {
        Write-TestMessage "Conflit détecté: $($conflict.ConflictId)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la détection du conflit" -Level "Error"
    }

    # Test 2: Vérifier le type de conflit
    Write-TestMessage "Test 2: Vérification du type de conflit" -Level "Info"

    if ($conflict.Type -eq [ConflictType]::WriteWrite) {
        Write-TestMessage "Type de conflit correct: $($conflict.Type)" -Level "Success"
    } else {
        Write-TestMessage "Type de conflit incorrect: $($conflict.Type)" -Level "Error"
    }

    # Test 3: Vérifier la sévérité du conflit
    Write-TestMessage "Test 3: Vérification de la sévérité du conflit" -Level "Info"

    if ($conflict.Severity -eq [ConflictSeverity]::High) {
        Write-TestMessage "Sévérité du conflit correcte: $($conflict.Severity)" -Level "Success"
    } else {
        Write-TestMessage "Sévérité du conflit incorrecte: $($conflict.Severity)" -Level "Error"
    }

    # Test 4: Vérifier la stratégie de résolution recommandée
    Write-TestMessage "Test 4: Vérification de la stratégie de résolution recommandée" -Level "Info"

    if ($conflict.RecommendedStrategy -eq [ResolutionStrategy]::MergeManual) {
        Write-TestMessage "Stratégie de résolution recommandée correcte: $($conflict.RecommendedStrategy)" -Level "Success"
    } else {
        Write-TestMessage "Stratégie de résolution recommandée incorrecte: $($conflict.RecommendedStrategy)" -Level "Error"
    }

    Write-TestMessage "Tests de détection des conflits terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'analyse des conflits de données
function Test-DataConflictAnalysis {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'analyse des conflits de données" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de conflits
    $options = @{
        ConflictLogPath      = $testDir
        EnableAutoResolution = $false
        EnableNotifications  = $true
        Debug                = $true
    }

    $conflictManager = [ConflictManager]::new("instance_test", $options)

    Write-TestMessage "Gestionnaire de conflits créé" -Level "Info"

    # Créer des données locales et distantes
    $localData = @{
        "resource1" = @{
            Version   = "1.0"
            Content   = "Contenu local 1"
            Timestamp = (Get-Date).AddMinutes(-5).ToString('o')
        }
        "resource2" = @{
            Version   = "1.0"
            Content   = "Contenu local 2"
            Timestamp = (Get-Date).AddMinutes(-10).ToString('o')
        }
        "resource3" = @{
            Version   = "1.0"
            Content   = "Contenu local 3"
            Timestamp = (Get-Date).AddMinutes(-15).ToString('o')
            Deleted   = $true
        }
    }

    $remoteData = @{
        "resource1" = @{
            Version   = "1.1"
            Content   = "Contenu distant 1"
            Timestamp = (Get-Date).ToString('o')
        }
        "resource2" = @{
            Version   = "1.0"
            Content   = "Contenu local 2"
            Timestamp = (Get-Date).AddMinutes(-10).ToString('o')
        }
        "resource3" = @{
            Version   = "1.1"
            Content   = "Contenu distant 3"
            Timestamp = (Get-Date).AddMinutes(-5).ToString('o')
        }
        "resource4" = @{
            Version   = "1.0"
            Content   = "Contenu distant 4"
            Timestamp = (Get-Date).AddMinutes(-20).ToString('o')
        }
    }

    # Analyser les conflits de données
    $conflicts = $conflictManager.AnalyzeDataConflicts($localData, $remoteData)

    # Test 1: Vérifier le nombre de conflits détectés
    Write-TestMessage "Test 1: Vérification du nombre de conflits détectés" -Level "Info"

    if ($conflicts.Count -eq 3) {
        Write-TestMessage "Nombre de conflits correct: $($conflicts.Count)" -Level "Success"
    } else {
        Write-TestMessage "Nombre de conflits incorrect: $($conflicts.Count)" -Level "Error"
    }

    # Test 2: Vérifier les types de conflits détectés
    Write-TestMessage "Test 2: Vérification des types de conflits détectés" -Level "Info"

    $versionMismatchConflict = $conflicts | Where-Object { $_.Type -eq [ConflictType]::VersionMismatch } | Select-Object -First 1
    $writeDeleteConflict = $conflicts | Where-Object { $_.Type -eq [ConflictType]::WriteDelete -or $_.Type -eq [ConflictType]::DeleteRead } | Select-Object -First 1

    if ($null -ne $versionMismatchConflict) {
        Write-TestMessage "Conflit de version détecté" -Level "Success"
    } else {
        Write-TestMessage "Conflit de version non détecté" -Level "Error"
    }

    if ($null -ne $writeDeleteConflict) {
        Write-TestMessage "Conflit d'écriture/suppression détecté" -Level "Success"
    } else {
        Write-TestMessage "Conflit d'écriture/suppression non détecté" -Level "Error"
    }

    Write-TestMessage "Tests d'analyse des conflits de données terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester les stratégies de résolution
function Test-ResolutionStrategies {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des stratégies de résolution" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de conflits
    $options = @{
        ConflictLogPath      = $testDir
        EnableAutoResolution = $false
        EnableNotifications  = $true
        Debug                = $true
    }

    $conflictManager = [ConflictManager]::new("instance_test", $options)

    Write-TestMessage "Gestionnaire de conflits créé" -Level "Info"

    # Créer un conflit
    $localState = @{
        Version    = "1.0"
        Content    = "Contenu local"
        Timestamp  = (Get-Date).AddMinutes(-5).ToString('o')
        ExtraLocal = "Donnée locale supplémentaire"
    }

    $remoteState = @{
        Version     = "1.1"
        Content     = "Contenu distant"
        Timestamp   = (Get-Date).ToString('o')
        ExtraRemote = "Donnée distante supplémentaire"
    }

    $conflict = $conflictManager.DetectConflict("resource1", [ConflictType]::WriteWrite, $localState, $remoteState)

    # Test 1: Résoudre le conflit avec la stratégie KeepLocal
    Write-TestMessage "Test 1: Résolution avec la stratégie KeepLocal" -Level "Info"

    $resolved = $conflictManager.ResolveConflict($conflict.ConflictId, [ResolutionStrategy]::KeepLocal)

    if ($resolved) {
        Write-TestMessage "Conflit résolu avec la stratégie KeepLocal" -Level "Success"
    } else {
        Write-TestMessage "Échec de la résolution du conflit avec la stratégie KeepLocal" -Level "Error"
    }

    # Vérifier que l'état fusionné est l'état local
    if ($conflict.MergedState.Content -eq "Contenu local") {
        Write-TestMessage "État fusionné correct: $($conflict.MergedState.Content)" -Level "Success"
    } else {
        Write-TestMessage "État fusionné incorrect: $($conflict.MergedState.Content)" -Level "Error"
    }

    # Test 2: Créer un nouveau conflit et le résoudre avec la stratégie MergeAutomatic
    Write-TestMessage "Test 2: Résolution avec la stratégie MergeAutomatic" -Level "Info"

    $conflict2 = $conflictManager.DetectConflict("resource2", [ConflictType]::WriteWrite, $localState, $remoteState)

    $resolved2 = $conflictManager.ResolveConflict($conflict2.ConflictId, [ResolutionStrategy]::MergeAutomatic)

    if ($resolved2) {
        Write-TestMessage "Conflit résolu avec la stratégie MergeAutomatic" -Level "Success"
    } else {
        Write-TestMessage "Échec de la résolution du conflit avec la stratégie MergeAutomatic" -Level "Error"
    }

    # Vérifier que l'état fusionné contient des éléments des deux états
    if ($conflict2.MergedState.Content -eq "Contenu distant" -and
        $conflict2.MergedState.ExtraLocal -eq "Donnée locale supplémentaire" -and
        $conflict2.MergedState.ExtraRemote -eq "Donnée distante supplémentaire") {
        Write-TestMessage "État fusionné correct avec les éléments des deux états" -Level "Success"
    } else {
        Write-TestMessage "État fusionné incorrect" -Level "Error"
    }

    Write-TestMessage "Tests des stratégies de résolution terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests du gestionnaire de conflits" -Level "Info"
Test-ConflictDetection
Test-DataConflictAnalysis
Test-ResolutionStrategies
Write-TestMessage "Tous les tests du gestionnaire de conflits sont terminés" -Level "Info"
