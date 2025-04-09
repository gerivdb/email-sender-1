<#
.SYNOPSIS
    Teste les améliorations apportées par la Phase 6 de la roadmap.

.DESCRIPTION
    Ce script teste les améliorations apportées par la Phase 6 de la roadmap, notamment :
    - La gestion d'erreurs dans les scripts
    - La compatibilité entre environnements

.PARAMETER ScriptsDirectory
    Le répertoire contenant les scripts à tester.

.PARAMETER TestErrorHandling
    Indique s'il faut tester la gestion d'erreurs.

.PARAMETER TestCompatibility
    Indique s'il faut tester la compatibilité entre environnements.

.PARAMETER LogFilePath
    Le chemin du fichier journal pour enregistrer les résultats des tests.

.EXAMPLE
    .\Test-Phase6Implementation.ps1 -ScriptsDirectory "..\..\scripts" -TestErrorHandling -TestCompatibility -LogFilePath "phase6_tests.log"

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 09/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsDirectory = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts"),
    
    [Parameter(Mandatory = $false)]
    [switch]$TestErrorHandling = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestCompatibility = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "phase6_tests.log")
)

# Fonction de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # Écrire dans le fichier journal
    try {
        # Créer le dossier de logs si nécessaire
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Impossible d'écrire dans le fichier journal : $_"
    }
}

# Fonction pour tester la gestion d'erreurs
function Test-ErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptsDirectory
    )
    
    Write-Log "Démarrage des tests de gestion d'erreurs"
    
    $results = @{
        Total = 0
        Passed = 0
        Failed = 0
        Details = @()
    }
    
    # Récupérer tous les scripts PowerShell dans le répertoire
    $scripts = Get-ChildItem -Path $ScriptsDirectory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
    $results.Total = $scripts.Count
    
    Write-Log "Nombre de scripts à tester : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Test de la gestion d'erreurs pour : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
            $results.Failed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Failed"
                Message = "Impossible de lire le contenu du script"
            }
            continue
        }
        
        # Vérifier la présence de blocs try/catch
        $hasTryCatch = $content -match "try\s*{" -and $content -match "catch\s*{"
        
        # Vérifier la présence de ErrorActionPreference
        $hasErrorActionPreference = $content -match "\`$ErrorActionPreference\s*=\s*['""]Stop['""]"
        
        # Vérifier la présence de gestion d'erreurs pour les commandes critiques
        $criticalCommands = @(
            "Remove-Item",
            "Set-Content",
            "Add-Content",
            "New-Item",
            "Copy-Item",
            "Move-Item",
            "Rename-Item",
            "Invoke-WebRequest",
            "Invoke-RestMethod",
            "Start-Process",
            "Stop-Process"
        )
        
        $hasCriticalCommands = $false
        $hasCriticalCommandsWithErrorHandling = $true
        
        foreach ($command in $criticalCommands) {
            if ($content -match $command) {
                $hasCriticalCommands = $true
                
                # Vérifier si la commande est entourée d'un bloc try/catch ou a un paramètre ErrorAction
                $commandWithErrorHandling = $content -match "try\s*{[^}]*$command" -or $content -match "$command[^}]*-ErrorAction"
                
                if (-not $commandWithErrorHandling) {
                    $hasCriticalCommandsWithErrorHandling = $false
                    break
                }
            }
        }
        
        # Déterminer si le script passe le test
        $passed = $hasTryCatch -or $hasErrorActionPreference -or (-not $hasCriticalCommands) -or $hasCriticalCommandsWithErrorHandling
        
        if ($passed) {
            Write-Log "Test de gestion d'erreurs réussi pour : $($script.FullName)" -Level "SUCCESS"
            $results.Passed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Passed"
                Message = "Le script a une gestion d'erreurs adéquate"
            }
        }
        else {
            Write-Log "Test de gestion d'erreurs échoué pour : $($script.FullName)" -Level "ERROR"
            $results.Failed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Failed"
                Message = "Le script n'a pas de gestion d'erreurs adéquate"
            }
        }
    }
    
    Write-Log "Tests de gestion d'erreurs terminés : $($results.Passed)/$($results.Total) réussis"
    
    return $results
}

# Fonction pour tester la compatibilité entre environnements
function Test-EnvironmentCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptsDirectory
    )
    
    Write-Log "Démarrage des tests de compatibilité entre environnements"
    
    $results = @{
        Total = 0
        Passed = 0
        Failed = 0
        Details = @()
    }
    
    # Récupérer tous les scripts PowerShell dans le répertoire
    $scripts = Get-ChildItem -Path $ScriptsDirectory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
    $results.Total = $scripts.Count
    
    Write-Log "Nombre de scripts à tester : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Test de la compatibilité entre environnements pour : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
            $results.Failed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Failed"
                Message = "Impossible de lire le contenu du script"
            }
            continue
        }
        
        # Vérifier la présence de chemins absolus Windows
        $hasWindowsPaths = $content -match "\\\\|[A-Za-z]:\\|\.exe\b|\.bat\b|\.cmd\b"
        
        # Vérifier l'utilisation de fonctions de gestion de chemins
        $hasPathFunctions = $content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path|Get-NormalizedPath"
        
        # Vérifier la présence de détection d'environnement
        $hasEnvironmentDetection = $content -match "Get-ScriptEnvironment|Test-Environment|\$IsWindows|\$IsLinux|\$IsMacOS"
        
        # Déterminer si le script passe le test
        $passed = (-not $hasWindowsPaths) -or $hasPathFunctions -or $hasEnvironmentDetection
        
        if ($passed) {
            Write-Log "Test de compatibilité entre environnements réussi pour : $($script.FullName)" -Level "SUCCESS"
            $results.Passed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Passed"
                Message = "Le script est compatible avec différents environnements"
            }
        }
        else {
            Write-Log "Test de compatibilité entre environnements échoué pour : $($script.FullName)" -Level "ERROR"
            $results.Failed++
            $results.Details += [PSCustomObject]@{
                Path = $script.FullName
                Status = "Failed"
                Message = "Le script n'est pas compatible avec différents environnements"
            }
        }
    }
    
    Write-Log "Tests de compatibilité entre environnements terminés : $($results.Passed)/$($results.Total) réussis"
    
    return $results
}

# Fonction principale
function Test-Phase6Implementation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptsDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$TestErrorHandling,
        
        [Parameter(Mandatory = $false)]
        [switch]$TestCompatibility
    )
    
    Write-Log "Démarrage des tests de la Phase 6"
    Write-Log "Répertoire des scripts : $ScriptsDirectory"
    
    # Vérifier si le répertoire des scripts existe
    if (-not (Test-Path -Path $ScriptsDirectory -PathType Container)) {
        Write-Log "Le répertoire des scripts n'existe pas : $ScriptsDirectory" -Level "ERROR"
        return $false
    }
    
    $results = @{
        ErrorHandling = $null
        Compatibility = $null
    }
    
    # Tester la gestion d'erreurs
    if ($TestErrorHandling) {
        $results.ErrorHandling = Test-ErrorHandling -ScriptsDirectory $ScriptsDirectory
    }
    
    # Tester la compatibilité entre environnements
    if ($TestCompatibility) {
        $results.Compatibility = Test-EnvironmentCompatibility -ScriptsDirectory $ScriptsDirectory
    }
    
    # Générer un rapport
    $report = [PSCustomObject]@{
        Date = Get-Date
        ScriptsDirectory = $ScriptsDirectory
        ErrorHandling = $results.ErrorHandling
        Compatibility = $results.Compatibility
    }
    
    # Enregistrer le rapport
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "phase6_test_report.json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath
    Write-Log "Rapport enregistré : $reportPath"
    
    Write-Log "Tests de la Phase 6 terminés"
    
    return $report
}

# Exécuter la fonction principale
$result = Test-Phase6Implementation -ScriptsDirectory $ScriptsDirectory -TestErrorHandling:$TestErrorHandling -TestCompatibility:$TestCompatibility

# Afficher un résumé
Write-Host "`nRésumé des tests de la Phase 6 :" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

if ($TestErrorHandling) {
    Write-Host "Gestion d'erreurs :" -ForegroundColor Yellow
    Write-Host "  - Scripts testés : $($result.ErrorHandling.Total)" -ForegroundColor White
    Write-Host "  - Tests réussis : $($result.ErrorHandling.Passed)" -ForegroundColor Green
    Write-Host "  - Tests échoués : $($result.ErrorHandling.Failed)" -ForegroundColor Red
    Write-Host "  - Taux de réussite : $(if ($result.ErrorHandling.Total -gt 0) { [math]::Round(($result.ErrorHandling.Passed / $result.ErrorHandling.Total) * 100, 2) } else { 0 })%" -ForegroundColor $(if ($result.ErrorHandling.Total -gt 0 -and ($result.ErrorHandling.Passed / $result.ErrorHandling.Total) -ge 0.8) { "Green" } else { "Yellow" })
}

if ($TestCompatibility) {
    Write-Host "`nCompatibilité entre environnements :" -ForegroundColor Yellow
    Write-Host "  - Scripts testés : $($result.Compatibility.Total)" -ForegroundColor White
    Write-Host "  - Tests réussis : $($result.Compatibility.Passed)" -ForegroundColor Green
    Write-Host "  - Tests échoués : $($result.Compatibility.Failed)" -ForegroundColor Red
    Write-Host "  - Taux de réussite : $(if ($result.Compatibility.Total -gt 0) { [math]::Round(($result.Compatibility.Passed / $result.Compatibility.Total) * 100, 2) } else { 0 })%" -ForegroundColor $(if ($result.Compatibility.Total -gt 0 -and ($result.Compatibility.Passed / $result.Compatibility.Total) -ge 0.8) { "Green" } else { "Yellow" })
}

Write-Host "`nRapport détaillé : $reportPath" -ForegroundColor Cyan
Write-Host "Journal : $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
