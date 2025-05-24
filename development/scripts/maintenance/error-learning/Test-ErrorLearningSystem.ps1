<#
.SYNOPSIS
    Script de test pour le systÃ¨me d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script gÃ©nÃ¨re des erreurs PowerShell pour tester le systÃ¨me d'apprentissage des erreurs.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$NumErrors = 5,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateDashboard
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# Fonction pour gÃ©nÃ©rer une erreur
function New-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ErrorType
    )

    switch ($ErrorType) {
        1 {
            # Division par zÃ©ro
            try {
                $result = 1 / 0
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "MathError" -Solution "Ã‰viter la division par zÃ©ro en vÃ©rifiant que le diviseur n'est pas Ã©gal Ã  zÃ©ro."
            }
        }
        2 {
            # Fichier introuvable
            try {
                Get-Content -Path "C:\fichier_inexistant.txt" -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "FileError" -Solution "VÃ©rifier que le fichier existe avant de tenter de le lire."
            }
        }
        3 {
            # AccÃ¨s Ã  une propriÃ©tÃ© inexistante
            try {
                $obj = New-Object -TypeName PSObject
                $value = $obj.ProprieteInexistante
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "PropertyError" -Solution "VÃ©rifier que la propriÃ©tÃ© existe avant d'y accÃ©der."
            }
        }
        4 {
            # Appel d'une commande inexistante
            try {
                Invoke-CommandeInexistante
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "CommandError" -Solution "VÃ©rifier que la commande existe avant de l'appeler."
            }
        }
        5 {
            # Erreur de syntaxe
            try {
                Invoke-Expression "if (1 -eq 1) { Write-Host 'Test' "
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "SyntaxError" -Solution "VÃ©rifier la syntaxe de l'expression."
            }
        }
        6 {
            # Erreur de type
            try {
                [int]"abc"
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "TypeError" -Solution "VÃ©rifier que la valeur peut Ãªtre convertie dans le type cible."
            }
        }
        7 {
            # Erreur d'argument
            try {
                Get-Process -Name
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "ArgumentError" -Solution "VÃ©rifier que les arguments sont correctement spÃ©cifiÃ©s."
            }
        }
        8 {
            # Erreur de permission
            try {
                New-Item -Path "C:\Windows\System32\test.txt" -ItemType File -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "PermissionError" -Solution "VÃ©rifier que l'utilisateur a les permissions nÃ©cessaires."
            }
        }
        9 {
            # Erreur de connexion
            try {
                Invoke-WebRequest -Uri "http://serveur_inexistant.local" -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "ConnectionError" -Solution "VÃ©rifier que le serveur est accessible et que la connexion rÃ©seau fonctionne."
            }
        }
        10 {
            # Erreur de timeout
            try {
                Invoke-WebRequest -Uri "http://example.com" -TimeoutSec 1 -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "TimeoutError" -Solution "Augmenter le dÃ©lai d'attente ou vÃ©rifier la connexion rÃ©seau."
            }
        }
    }
}

# GÃ©nÃ©rer des erreurs
Write-Host "GÃ©nÃ©ration de $NumErrors erreurs..." -ForegroundColor Cyan

for ($i = 1; $i -le $NumErrors; $i++) {
    $errorType = Get-Random -Minimum 1 -Maximum 11
    Write-Host "GÃ©nÃ©ration de l'erreur $i (type $errorType)..." -ForegroundColor Yellow
    New-Error -ErrorType $errorType
}

Write-Host "GÃ©nÃ©ration d'erreurs terminÃ©e." -ForegroundColor Green

# Analyser les erreurs
$analysisResult = Get-PowerShellErrorAnalysis -IncludeStatistics
$totalErrors = $analysisResult.Statistics.TotalErrors
$categories = $analysisResult.Statistics.CategorizedErrors

Write-Host "`nAnalyse des erreurs :"
Write-Host "Total des erreurs enregistrÃ©es : $totalErrors"
Write-Host "`nRÃ©partition par catÃ©gorie :"

foreach ($category in $categories.Keys) {
    $count = $categories[$category]
    $percentage = [math]::Round(($count / $totalErrors) * 100, 2)
    Write-Host "  $category : $count ($percentage%)"
}

# GÃ©nÃ©rer le tableau de bord si demandÃ©
if ($GenerateDashboard) {
    $dashboardPath = Join-Path -Path $PSScriptRoot -ChildPath "dashboard\error-dashboard.html"

    # GÃ©nÃ©rer le tableau de bord
    & (Join-Path -Path $PSScriptRoot -ChildPath "Generate-ErrorDashboard.ps1") -OutputPath $dashboardPath -OpenInBrowser
}

Write-Host "`nTest terminÃ©." -ForegroundColor Green

