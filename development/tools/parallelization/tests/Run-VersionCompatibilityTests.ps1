# Script pour exécuter les tests de compatibilité sur PowerShell 5.1 et 7.x
# Ce script lance les tests sur les différentes versions de PowerShell installées

# Fonction pour exécuter les tests sur une version spécifique de PowerShell
function Invoke-TestsOnPowerShellVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$VersionName
    )
    
    Write-Host "=== Exécution des tests sur $VersionName ===" -ForegroundColor Cyan
    Write-Host "Chemin PowerShell: $PowerShellPath" -ForegroundColor Cyan
    Write-Host "Chemin du script de test: $TestScriptPath" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    
    # Exécuter le script de test avec la version spécifiée de PowerShell
    & $PowerShellPath -NoProfile -ExecutionPolicy Bypass -File $TestScriptPath
    
    Write-Host "=== Fin des tests sur $VersionName ===" -ForegroundColor Cyan
    Write-Host ""
}

# Chemin du script de test
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-PSVersionCompatibility.ps1"

# Vérifier que le script de test existe
if (-not (Test-Path -Path $testScriptPath)) {
    Write-Host "ERREUR: Le script de test n'existe pas: $testScriptPath" -ForegroundColor Red
    exit 1
}

# Chemins des différentes versions de PowerShell
$ps51Path = "powershell.exe"
$ps7Path = "pwsh.exe"

# Vérifier si PowerShell 5.1 est disponible
$ps51Available = $true
try {
    $ps51Version = & $ps51Path -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    if (-not $ps51Version) {
        $ps51Available = $false
        Write-Host "AVERTISSEMENT: PowerShell 5.1 n'est pas disponible." -ForegroundColor Yellow
    }
} catch {
    $ps51Available = $false
    Write-Host "AVERTISSEMENT: PowerShell 5.1 n'est pas disponible: $_" -ForegroundColor Yellow
}

# Vérifier si PowerShell 7.x est disponible
$ps7Available = $true
try {
    $ps7Version = & $ps7Path -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    if (-not $ps7Version) {
        $ps7Available = $false
        Write-Host "AVERTISSEMENT: PowerShell 7.x n'est pas disponible." -ForegroundColor Yellow
    }
} catch {
    $ps7Available = $false
    Write-Host "AVERTISSEMENT: PowerShell 7.x n'est pas disponible: $_" -ForegroundColor Yellow
}

# Exécuter les tests sur PowerShell 5.1 si disponible
if ($ps51Available) {
    Invoke-TestsOnPowerShellVersion -PowerShellPath $ps51Path -TestScriptPath $testScriptPath -VersionName "PowerShell 5.1 ($ps51Version)"
}

# Exécuter les tests sur PowerShell 7.x si disponible
if ($ps7Available) {
    Invoke-TestsOnPowerShellVersion -PowerShellPath $ps7Path -TestScriptPath $testScriptPath -VersionName "PowerShell 7.x ($ps7Version)"
}

# Vérifier si au moins une version de PowerShell est disponible
if (-not ($ps51Available -or $ps7Available)) {
    Write-Host "ERREUR: Aucune version de PowerShell n'est disponible pour exécuter les tests." -ForegroundColor Red
    exit 1
}

Write-Host "=== Tous les tests sont terminés ===" -ForegroundColor Cyan
