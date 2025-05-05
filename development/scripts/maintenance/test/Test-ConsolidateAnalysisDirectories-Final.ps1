#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le script Consolidate-AnalysisDirectories-Final.ps1.
.DESCRIPTION
    Ce script exÃ©cute des tests pour vÃ©rifier le bon fonctionnement du script
    Consolidate-AnalysisDirectories-Final.ps1.
.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script exÃ©cute les tests en mode simulation.
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

# DÃ©finir le rÃ©pertoire racine du dÃ©pÃ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃ©rifier que le rÃ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃ©pertoire racine n'existe pas : $repoRoot"
}

# DÃ©finir les chemins des dossiers source et destination
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

# VÃ©rifier que les dossiers source existent
Write-TestMessage "VÃ©rification des dossiers source..." -Type "Info"

$testsPassed = $true

if (-not (Test-Path -Path $analysisPath -PathType Container)) {
    Write-TestMessage "Ã‰CHEC : Le dossier analysis n'existe pas : $analysisPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÃˆS : Le dossier analysis existe : $analysisPath" -Type "Success"
}

if (-not (Test-Path -Path $analyticsPath -PathType Container)) {
    Write-TestMessage "Ã‰CHEC : Le dossier analytics n'existe pas : $analyticsPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÃˆS : Le dossier analytics existe : $analyticsPath" -Type "Success"
}

# VÃ©rifier que le script de consolidation existe
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Consolidate-AnalysisDirectories-Final.ps1"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-TestMessage "Ã‰CHEC : Le script de consolidation n'existe pas : $scriptPath" -Type "Error"
    $testsPassed = $false
} else {
    Write-TestMessage "SUCCÃˆS : Le script de consolidation existe : $scriptPath" -Type "Success"
}

# ExÃ©cuter le script en mode DryRun pour tester
if ($testsPassed) {
    Write-TestMessage "ExÃ©cution du script en mode DryRun pour tester..." -Type "Info"
    
    try {
        & $scriptPath -DryRun -Force
        Write-TestMessage "SUCCÃˆS : Le script s'est exÃ©cutÃ© sans erreur en mode DryRun" -Type "Success"
    } catch {
        Write-TestMessage "Ã‰CHEC : Le script a gÃ©nÃ©rÃ© une erreur en mode DryRun : $_" -Type "Error"
        $testsPassed = $false
    }
}

# VÃ©rifier que les dossiers de destination existent aprÃ¨s l'exÃ©cution rÃ©elle
if ($testsPassed -and -not $DryRun) {
    Write-TestMessage "ExÃ©cution du script en mode rÃ©el pour tester..." -Type "Info"
    
    try {
        & $scriptPath -Force
        Write-TestMessage "SUCCÃˆS : Le script s'est exÃ©cutÃ© sans erreur en mode rÃ©el" -Type "Success"
        
        # VÃ©rifier que les dossiers de destination ont Ã©tÃ© crÃ©Ã©s
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
                Write-TestMessage "Ã‰CHEC : Le dossier de destination n'a pas Ã©tÃ© crÃ©Ã© : $folderPath" -Type "Error"
                $testsPassed = $false
            } else {
                Write-TestMessage "SUCCÃˆS : Le dossier de destination a Ã©tÃ© crÃ©Ã© : $folderPath" -Type "Success"
            }
        }
        
        # VÃ©rifier que le fichier README.md a Ã©tÃ© crÃ©Ã©
        $readmePath = Join-Path -Path $unifiedPath -ChildPath "README.md"
        
        if (-not (Test-Path -Path $readmePath -PathType Leaf)) {
            Write-TestMessage "Ã‰CHEC : Le fichier README.md n'a pas Ã©tÃ© crÃ©Ã© : $readmePath" -Type "Error"
            $testsPassed = $false
        } else {
            Write-TestMessage "SUCCÃˆS : Le fichier README.md a Ã©tÃ© crÃ©Ã© : $readmePath" -Type "Success"
        }
        
        # VÃ©rifier que le fichier de redirection a Ã©tÃ© crÃ©Ã©
        $redirectPath = Join-Path -Path $analyticsPath -ChildPath "README.md"
        
        if (-not (Test-Path -Path $redirectPath -PathType Leaf)) {
            Write-TestMessage "Ã‰CHEC : Le fichier de redirection n'a pas Ã©tÃ© crÃ©Ã© : $redirectPath" -Type "Error"
            $testsPassed = $false
        } else {
            Write-TestMessage "SUCCÃˆS : Le fichier de redirection a Ã©tÃ© crÃ©Ã© : $redirectPath" -Type "Success"
        }
    } catch {
        Write-TestMessage "Ã‰CHEC : Le script a gÃ©nÃ©rÃ© une erreur en mode rÃ©el : $_" -Type "Error"
        $testsPassed = $false
    }
}

# Afficher le rÃ©sultat final
if ($testsPassed) {
    Write-TestMessage "TOUS LES TESTS ONT RÃ‰USSI" -Type "Success"
} else {
    Write-TestMessage "CERTAINS TESTS ONT Ã‰CHOUÃ‰" -Type "Error"
}

# Retourner le rÃ©sultat
return $testsPassed
