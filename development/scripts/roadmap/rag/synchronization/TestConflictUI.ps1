<#
.SYNOPSIS
    Script de test pour l'interface de résolution manuelle des conflits.

.DESCRIPTION
    Ce script teste le fonctionnement de l'interface de résolution manuelle des conflits,
    notamment l'affichage des différences, la sélection des éléments à conserver et la
    validation des choix de l'utilisateur.

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
$conflictResolutionUIPath = Join-Path -Path $scriptDir -ChildPath "ConflictResolutionUI.ps1"

if (Test-Path -Path $conflictManagerPath) {
    . $conflictManagerPath
} else {
    throw "Le module ConflictManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictManagerPath"
}

if (Test-Path -Path $conflictResolutionUIPath) {
    . $conflictResolutionUIPath
} else {
    throw "Le module ConflictResolutionUI.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictResolutionUIPath"
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
        [string]$DirectoryName = "ConflictResolutionUITest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour simuler les entrées utilisateur
function Set-MockUserInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Inputs
    )

    # Créer un script temporaire qui simule les entrées utilisateur
    $tempScript = @"
`$inputs = @(
$(($Inputs | ForEach-Object { "'$_'" }) -join ",`n")
)

`$inputIndex = 0

function Read-Host {
    param([string]`$prompt)

    Write-Host "`$prompt" -NoNewline
    `$input = `$inputs[`$script:inputIndex]
    `$script:inputIndex++
    Write-Host " `$input"
    return `$input
}
"@

    $tempScriptPath = Join-Path -Path $env:TEMP -ChildPath "MockUserInput_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $tempScript | Out-File -FilePath $tempScriptPath -Encoding utf8

    # Charger le script temporaire
    . $tempScriptPath

    # Supprimer le script temporaire
    Remove-Item -Path $tempScriptPath -Force
}

# Fonction pour tester l'analyse des différences
function Test-DifferenceAnalysis {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'analyse des différences" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de conflits
    $options = @{
        ConflictLogPath      = $testDir
        EnableAutoResolution = $false
        EnableNotifications  = $false
        Debug                = $true
    }

    $conflictManager = [ConflictManager]::new("instance_test", $options)

    Write-TestMessage "Gestionnaire de conflits créé" -Level "Info"

    # Créer un conflit
    $localState = @{
        Version   = "1.0"
        Content   = "Contenu local"
        Timestamp = (Get-Date).AddMinutes(-5).ToString('o')
        Metadata  = @{
            Author = "Utilisateur local"
            Tags   = @("tag1", "tag2")
        }
    }

    $remoteState = @{
        Version   = "1.1"
        Content   = "Contenu distant"
        Timestamp = (Get-Date).ToString('o')
        Metadata  = @{
            Author    = "Utilisateur distant"
            Tags      = @("tag1", "tag3")
            ExtraInfo = "Information supplémentaire"
        }
    }

    $conflict = $conflictManager.DetectConflict("resource1", [ConflictType]::WriteWrite, $localState, $remoteState)

    Write-TestMessage "Conflit créé: $($conflict.ConflictId)" -Level "Info"

    # Créer une interface de résolution manuelle
    $uiOptions = @{
        UseConsoleUI = $true
        Debug        = $true
    }

    $ui = [ConflictResolutionUI]::new($conflict, $uiOptions)

    Write-TestMessage "Interface de résolution manuelle créée" -Level "Info"

    # Test 1: Vérifier le nombre de différences détectées
    Write-TestMessage "Test 1: Vérification du nombre de différences détectées" -Level "Info"

    $expectedDifferenceCount = 6  # Version, Content, Timestamp, Metadata.Author, Metadata.Tags, Metadata.ExtraInfo

    if ($ui.Differences.Count -eq $expectedDifferenceCount) {
        Write-TestMessage "Nombre de différences correct: $($ui.Differences.Count)" -Level "Success"
    } else {
        Write-TestMessage "Nombre de différences incorrect: $($ui.Differences.Count), attendu: $expectedDifferenceCount" -Level "Error"
    }

    # Test 2: Vérifier que les différences sont correctement identifiées
    Write-TestMessage "Test 2: Vérification des différences identifiées" -Level "Info"

    $versionDifference = $ui.Differences | Where-Object { $_.PropertyPath -eq "Version" } | Select-Object -First 1
    $contentDifference = $ui.Differences | Where-Object { $_.PropertyPath -eq "Content" } | Select-Object -First 1
    $extraInfoDifference = $ui.Differences | Where-Object { $_.PropertyPath -eq "Metadata.ExtraInfo" } | Select-Object -First 1

    if ($null -ne $versionDifference -and $versionDifference.IsConflict) {
        Write-TestMessage "Différence de version correctement identifiée" -Level "Success"
    } else {
        Write-TestMessage "Différence de version non identifiée correctement" -Level "Error"
    }

    if ($null -ne $contentDifference -and $contentDifference.IsConflict) {
        Write-TestMessage "Différence de contenu correctement identifiée" -Level "Success"
    } else {
        Write-TestMessage "Différence de contenu non identifiée correctement" -Level "Error"
    }

    if ($null -ne $extraInfoDifference -and $extraInfoDifference.IsConflict) {
        Write-TestMessage "Différence d'information supplémentaire correctement identifiée" -Level "Success"
    } else {
        Write-TestMessage "Différence d'information supplémentaire non identifiée correctement" -Level "Error"
    }

    Write-TestMessage "Tests d'analyse des différences terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests de l'interface de résolution manuelle des conflits" -Level "Info"
Test-DifferenceAnalysis
Write-TestMessage "Tous les tests de l'interface de résolution manuelle des conflits sont terminés" -Level "Info"
