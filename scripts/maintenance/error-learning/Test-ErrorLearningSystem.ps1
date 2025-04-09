<#
.SYNOPSIS
    Script de test pour le système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script génère des erreurs PowerShell pour tester le système d'apprentissage des erreurs.
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

# Initialiser le système
Initialize-ErrorLearningSystem

# Fonction pour générer une erreur
function Generate-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ErrorType
    )
    
    switch ($ErrorType) {
        1 {
            # Division par zéro
            try {
                $result = 1 / 0
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "MathError" -Solution "Éviter la division par zéro en vérifiant que le diviseur n'est pas égal à zéro."
            }
        }
        2 {
            # Fichier introuvable
            try {
                Get-Content -Path "C:\fichier_inexistant.txt" -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "FileError" -Solution "Vérifier que le fichier existe avant de tenter de le lire."
            }
        }
        3 {
            # Accès à une propriété inexistante
            try {
                $obj = New-Object -TypeName PSObject
                $value = $obj.ProprieteInexistante
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "PropertyError" -Solution "Vérifier que la propriété existe avant d'y accéder."
            }
        }
        4 {
            # Appel d'une commande inexistante
            try {
                Invoke-CommandeInexistante
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "CommandError" -Solution "Vérifier que la commande existe avant de l'appeler."
            }
        }
        5 {
            # Erreur de syntaxe
            try {
                Invoke-Expression "if (1 -eq 1) { Write-Host 'Test' "
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "SyntaxError" -Solution "Vérifier la syntaxe de l'expression."
            }
        }
        6 {
            # Erreur de type
            try {
                [int]"abc"
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "TypeError" -Solution "Vérifier que la valeur peut être convertie dans le type cible."
            }
        }
        7 {
            # Erreur d'argument
            try {
                Get-Process -Name
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "ArgumentError" -Solution "Vérifier que les arguments sont correctement spécifiés."
            }
        }
        8 {
            # Erreur de permission
            try {
                New-Item -Path "C:\Windows\System32\test.txt" -ItemType File -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "PermissionError" -Solution "Vérifier que l'utilisateur a les permissions nécessaires."
            }
        }
        9 {
            # Erreur de connexion
            try {
                Invoke-WebRequest -Uri "http://serveur_inexistant.local" -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "ConnectionError" -Solution "Vérifier que le serveur est accessible et que la connexion réseau fonctionne."
            }
        }
        10 {
            # Erreur de timeout
            try {
                Invoke-WebRequest -Uri "http://example.com" -TimeoutSec 1 -ErrorAction Stop
            }
            catch {
                Register-PowerShellError -ErrorRecord $_ -Source "Test-ErrorLearningSystem" -Category "TimeoutError" -Solution "Augmenter le délai d'attente ou vérifier la connexion réseau."
            }
        }
    }
}

# Générer des erreurs
Write-Host "Génération de $NumErrors erreurs..." -ForegroundColor Cyan

for ($i = 1; $i -le $NumErrors; $i++) {
    $errorType = Get-Random -Minimum 1 -Maximum 11
    Write-Host "Génération de l'erreur $i (type $errorType)..." -ForegroundColor Yellow
    Generate-Error -ErrorType $errorType
}

Write-Host "Génération d'erreurs terminée." -ForegroundColor Green

# Analyser les erreurs
$analysisResult = Analyze-PowerShellErrors -IncludeStatistics
$totalErrors = $analysisResult.Statistics.TotalErrors
$categories = $analysisResult.Statistics.CategorizedErrors

Write-Host "`nAnalyse des erreurs :"
Write-Host "Total des erreurs enregistrées : $totalErrors"
Write-Host "`nRépartition par catégorie :"

foreach ($category in $categories.Keys) {
    $count = $categories[$category]
    $percentage = [math]::Round(($count / $totalErrors) * 100, 2)
    Write-Host "  $category : $count ($percentage%)"
}

# Générer le tableau de bord si demandé
if ($GenerateDashboard) {
    $dashboardPath = Join-Path -Path $PSScriptRoot -ChildPath "dashboard\error-dashboard.html"
    
    # Générer le tableau de bord
    & (Join-Path -Path $PSScriptRoot -ChildPath "Generate-ErrorDashboard.ps1") -OutputPath $dashboardPath -OpenInBrowser
}

Write-Host "`nTest terminé." -ForegroundColor Green
