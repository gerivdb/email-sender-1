#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le script Consolidate-AnalysisDirectories-Final.ps1.
.DESCRIPTION
    Ce script exécute des tests pour vérifier le bon fonctionnement du script
    Consolidate-AnalysisDirectories-Final.ps1.
.PARAMETER DryRun
    Si spécifié, le script exécute les tests en mode simulation.
.EXAMPLE
    .\Test-ConsolidateAnalysisDirectories-Final.ps1
.EXAMPLE
    .\Test-ConsolidateAnalysisDirectories-Final.ps1 -DryRun
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2023-12-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Définir le répertoire racine du dépôt
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# Vérifier que le répertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le répertoire racine n'existe pas : $repoRoot"
}

# Définir les chemins des dossiers source et destination
$analysisPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"
$analyticsPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analytics"
$unifiedPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"

# Fonction pour afficher les messages
function Write-TestMessage {
    param (
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    Write-Host $Message -ForegroundColor $color
}

# Vérifier que les dossiers source existent
Write-TestMessage "Vérification des dossiers source..." -Type "Info"

$testsPassed = $true

if (-not (Test-Path -Path $analysisPath -PathType Container)) {
    Write-TestMessage "ÉCHEC : Le dossier analysis n'existe pas : $analysisPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÈS : Le dossier analysis existe : $analysisPath" -Type "Success"
}

if (-not (Test-Path -Path $analyticsPath -PathType Container)) {
    Write-TestMessage "ÉCHEC : Le dossier analytics n'existe pas : $analyticsPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÈS : Le dossier analytics existe : $analyticsPath" -Type "Success"
}

# Vérifier que le script de consolidation existe
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Consolidate-AnalysisDirectories-Final.ps1"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-TestMessage "ÉCHEC : Le script de consolidation n'existe pas : $scriptPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÈS : Le script de consolidation existe : $scriptPath" -Type "Success"
}

# Exécuter le script en mode DryRun pour tester
if ($testsPassed) {
    Write-TestMessage "Exécution du script en mode DryRun pour tester..." -Type "Info"
    
    try {
        & $scriptPath -DryRun -Force
        Write-TestMessage "SUCCÈS : Le script s'est exécuté sans erreur en mode DryRun" -Type "Success"
    } catch {
        Write-TestMessage "ÉCHEC : Le script a généré une erreur en mode DryRun : $_" -Type "Error"
        $testsPassed = $false
    }
}

# Vérifier que les dossiers de destination existent après l'exécution réelle
if ($testsPassed -and -not $DryRun) {
    Write-TestMessage "Exécution du script en mode réel pour tester..." -Type "Info"
    
    try {
        & $scriptPath -Force
        Write-TestMessage "SUCCÈS : Le script s'est exécuté sans erreur en mode réel" -Type "Success"
        
        # Vérifier que les dossiers de destination ont été créés
        $newFolders = @(
            "code",
            "performance",
            "data",
            "reporting",
            "integration",
            "roadmap",
            "common"
        )
        
        foreach ($folder in $newFolders) {
            $folderPath = Join-Path -Path $unifiedPath -ChildPath $folder
            
            if (-not (Test-Path -Path $folderPath -PathType Container)) {
                Write-TestMessage "ÉCHEC : Le dossier de destination n'a pas été créé : $folderPath" -Type "Error"
                $testsPassed = $false
            } else {
                Write-TestMessage "SUCCÈS : Le dossier de destination a été créé : $folderPath" -Type "Success"
            }
        }
        
        # Vérifier que le fichier README.md a été créé
        $readmePath = Join-Path -Path $unifiedPath -ChildPath "README.md"
        
        if (-not (Test-Path -Path $readmePath -PathType Leaf)) {
            Write-TestMessage "ÉCHEC : Le fichier README.md n'a pas été créé : $readmePath" -Type "Error"
            $testsPassed = $false
        } else {
            Write-TestMessage "SUCCÈS : Le fichier README.md a été créé : $readmePath" -Type "Success"
        }
        
        # Vérifier que le fichier de redirection a été créé
        $redirectPath = Join-Path -Path $analyticsPath -ChildPath "README.md"
        
        if (-not (Test-Path -Path $redirectPath -PathType Leaf)) {
            Write-TestMessage "ÉCHEC : Le fichier de redirection n'a pas été créé : $redirectPath" -Type "Error"
            $testsPassed = $false
        } else {
            Write-TestMessage "SUCCÈS : Le fichier de redirection a été créé : $redirectPath" -Type "Success"
        }
    } catch {
        Write-TestMessage "ÉCHEC : Le script a généré une erreur en mode réel : $_" -Type "Error"
        $testsPassed = $false
    }
}

# Afficher le résultat final
if ($testsPassed) {
    Write-TestMessage "TOUS LES TESTS ONT RÉUSSI" -Type "Success"
} else {
    Write-TestMessage "CERTAINS TESTS ONT ÉCHOUÉ" -Type "Error"
}

# Retourner le résultat
return $testsPassed
