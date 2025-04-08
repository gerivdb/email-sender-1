<#
.SYNOPSIS
    Teste la Phase 4 : Amélioration du système de gestion de scripts.
.DESCRIPTION
    Ce script teste spécifiquement la Phase 4 du projet de réorganisation des scripts,
    qui concerne l'amélioration du système de gestion de scripts. Il vérifie que le
    ScriptManager fonctionne correctement et qu'il intègre toutes les fonctionnalités
    des phases précédentes.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par défaut: scripts\tests\scriptmanager_test_report.json
.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Test-Phase4-ScriptManager.ps1
    Teste la Phase 4 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase4-ScriptManager.ps1 -Path "scripts\maintenance" -Verbose
    Teste la Phase 4 sur les scripts du dossier "scripts\maintenance" avec des informations détaillées.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\scriptmanager_test_report.json",
    [switch]$Verbose
)

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE", "TEST")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
        "TEST" = "Magenta"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour tester une fonctionnalité du ScriptManager
function Test-ScriptManagerFeature {
    param (
        [string]$Name,
        [string]$Command,
        [string]$ExpectedOutputPath = $null,
        [switch]$Verbose
    )
    
    Write-Log "Test de la fonctionnalité: $Name" -Level "TEST"
    
    if ($Verbose) {
        Write-Log "Exécution de la commande: $Command" -Level "INFO"
    }
    
    try {
        # Exécuter la commande
        Invoke-Expression $Command
        
        # Vérifier si un fichier de sortie est attendu
        if ($ExpectedOutputPath -and -not (Test-Path -Path $ExpectedOutputPath)) {
            Write-Log "Le fichier de sortie n'a pas été généré: $ExpectedOutputPath" -Level "ERROR"
            return @{
                Name = $Name
                Success = $false
                Error = "Le fichier de sortie n'a pas été généré: $ExpectedOutputPath"
            }
        }
        
        Write-Log "Test réussi: $Name" -Level "SUCCESS"
        return @{
            Name = $Name
            Success = $true
            Error = $null
        }
    } catch {
        Write-Log "Erreur lors du test: $_" -Level "ERROR"
        return @{
            Name = $Name
            Success = $false
            Error = $_.ToString()
        }
    }
}

# Fonction principale
function Test-ScriptManager {
    param (
        [string]$Path,
        [string]$OutputPath,
        [switch]$Verbose
    )
    
    Write-Log "=== Test de la Phase 4 : Amélioration du système de gestion de scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "INFO"
    }
    
    # Vérifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\manager\ScriptManager.ps1"
    if (-not (Test-Path -Path $ScriptManagerPath)) {
        Write-Log "Le ScriptManager n'existe pas: $ScriptManagerPath" -Level "ERROR"
        
        $Results = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Success = $false
            Error = "Le ScriptManager n'existe pas: $ScriptManagerPath"
            Tests = @()
        }
        
        $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
        
        return $false
    }
    
    # Définir les tests à exécuter
    $Tests = @(
        @{
            Name = "Inventaire"
            Command = "& '$ScriptManagerPath' -Action inventory -Path '$Path'"
            ExpectedOutputPath = "scripts\manager\data\inventory.json"
        },
        @{
            Name = "Analyse"
            Command = "& '$ScriptManagerPath' -Action analyze -Path '$Path'"
            ExpectedOutputPath = "scripts\manager\data\analysis.json"
        },
        @{
            Name = "Standardisation"
            Command = "& '$ScriptManagerPath' -Action standardize -Path '$Path'"
            ExpectedOutputPath = $null
        },
        @{
            Name = "Élimination des duplications"
            Command = "& '$ScriptManagerPath' -Action deduplicate -Path '$Path'"
            ExpectedOutputPath = $null
        },
        @{
            Name = "Documentation"
            Command = "& '$ScriptManagerPath' -Action document -Path '$Path' -Format Markdown"
            ExpectedOutputPath = "scripts\manager\docs\script_documentation.markdown"
        },
        @{
            Name = "Tableau de bord"
            Command = "& '$ScriptManagerPath' -Action dashboard"
            ExpectedOutputPath = $null
        }
    )
    
    # Exécuter les tests
    $TestResults = @()
    foreach ($Test in $Tests) {
        $Result = Test-ScriptManagerFeature -Name $Test.Name -Command $Test.Command -ExpectedOutputPath $Test.ExpectedOutputPath -Verbose:$Verbose
        $TestResults += $Result
    }
    
    # Calculer le résultat global
    $SuccessCount = ($TestResults | Where-Object { $_.Success -eq $true }).Count
    $TotalCount = $TestResults.Count
    $Success = $SuccessCount -ge ($TotalCount / 2)
    
    # Enregistrer les résultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Success = $Success
        SuccessCount = $SuccessCount
        TotalCount = $TotalCount
        Tests = $TestResults
    }
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    Write-Log "Tests terminés" -Level "SUCCESS"
    Write-Log "Nombre de tests réussis: $SuccessCount / $TotalCount" -Level $(if ($Success) { "SUCCESS" } else { "WARNING" })
    
    foreach ($Result in $TestResults) {
        $StatusColor = if ($Result.Success) { "SUCCESS" } else { "ERROR" }
        $StatusText = if ($Result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
        Write-Log "  $($Result.Name): $StatusText" -Level $StatusColor
        
        if (-not $Result.Success) {
            Write-Log "    Erreur: $($Result.Error)" -Level "ERROR"
        }
    }
    
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    
    # Déterminer si le test est réussi
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Tous les tests ont réussi" -Level "SUCCESS"
        Write-Log "La Phase 4 a réussi" -Level "SUCCESS"
        return $true
    } elseif ($Success) {
        Write-Log "La plupart des tests ont réussi" -Level "WARNING"
        Write-Log "La Phase 4 a partiellement réussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des tests ont échoué" -Level "ERROR"
        Write-Log "La Phase 4 n'a pas réussi" -Level "ERROR"
        return $false
    }
}

# Exécuter le test
$Success = Test-ScriptManager -Path $Path -OutputPath $OutputPath -Verbose:$Verbose

# Retourner le résultat
return $Success
