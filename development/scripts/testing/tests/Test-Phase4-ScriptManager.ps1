<#
.SYNOPSIS
    Teste la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts.
.DESCRIPTION
    Ce script teste spÃ©cifiquement la Phase 4 du projet de rÃ©organisation des scripts,
    qui concerne l'amÃ©lioration du systÃ¨me de gestion de scripts. Il vÃ©rifie que le
    ScriptManager fonctionne correctement et qu'il intÃ¨gre toutes les fonctionnalitÃ©s
    des phases prÃ©cÃ©dentes.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par dÃ©faut: scripts\tests\scriptmanager_test_report.json
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-Phase4-ScriptManager.ps1
    Teste la Phase 4 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase4-ScriptManager.ps1 -Path "scripts\maintenance" -Verbose
    Teste la Phase 4 sur les scripts du dossier "scripts\maintenance" avec des informations dÃ©taillÃ©es.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\scriptmanager_test_report.json",
    [switch]$Verbose
)

# Fonction pour Ã©crire des messages de log
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
    
    # Ã‰crire dans un fichier de log
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour tester une fonctionnalitÃ© du ScriptManager
function Test-ScriptManagerFeature {
    param (
        [string]$Name,
        [string]$Command,
        [string]$ExpectedOutputPath = $null,
        [switch]$Verbose
    )
    
    Write-Log "Test de la fonctionnalitÃ©: $Name" -Level "TEST"
    
    if ($Verbose) {
        Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    }
    
    try {
        # ExÃ©cuter la commande
        Invoke-Expression $Command
        
        # VÃ©rifier si un fichier de sortie est attendu
        if ($ExpectedOutputPath -and -not (Test-Path -Path $ExpectedOutputPath)) {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $ExpectedOutputPath" -Level "ERROR"
            return @{
                Name = $Name
                Success = $false
                Error = "Le fichier de sortie n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $ExpectedOutputPath"
            }
        }
        
        Write-Log "Test rÃ©ussi: $Name" -Level "SUCCESS"
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
    
    Write-Log "=== Test de la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts Ã  tester: $Path" -Level "INFO"
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "INFO"
    }
    
    # VÃ©rifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\\mode-manager\ScriptManager.ps1"
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
    
    # DÃ©finir les tests Ã  exÃ©cuter
    $Tests = @(
        @{
            Name = "Inventaire"
            Command = "& '$ScriptManagerPath' -Action inventory -Path '$Path'"
            ExpectedOutputPath = "scripts\\mode-manager\data\inventory.json"
        },
        @{
            Name = "Analyse"
            Command = "& '$ScriptManagerPath' -Action analyze -Path '$Path'"
            ExpectedOutputPath = "scripts\\mode-manager\data\analysis.json"
        },
        @{
            Name = "Standardisation"
            Command = "& '$ScriptManagerPath' -Action standardize -Path '$Path'"
            ExpectedOutputPath = $null
        },
        @{
            Name = "Ã‰limination des duplications"
            Command = "& '$ScriptManagerPath' -Action deduplicate -Path '$Path'"
            ExpectedOutputPath = $null
        },
        @{
            Name = "Documentation"
            Command = "& '$ScriptManagerPath' -Action document -Path '$Path' -Format Markdown"
            ExpectedOutputPath = "scripts\\mode-manager\docs\script_documentation.markdown"
        },
        @{
            Name = "Tableau de bord"
            Command = "& '$ScriptManagerPath' -Action dashboard"
            ExpectedOutputPath = $null
        }
    )
    
    # ExÃ©cuter les tests
    $TestResults = @()
    foreach ($Test in $Tests) {
        $Result = Test-ScriptManagerFeature -Name $Test.Name -Command $Test.Command -ExpectedOutputPath $Test.ExpectedOutputPath -Verbose:$Verbose
        $TestResults += $Result
    }
    
    # Calculer le rÃ©sultat global
    $SuccessCount = ($TestResults | Where-Object { $_.Success -eq $true }).Count
    $TotalCount = $TestResults.Count
    $Success = $SuccessCount -ge ($TotalCount / 2)
    
    # Enregistrer les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Success = $Success
        SuccessCount = $SuccessCount
        TotalCount = $TotalCount
        Tests = $TestResults
    }
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    Write-Log "Tests terminÃ©s" -Level "SUCCESS"
    Write-Log "Nombre de tests rÃ©ussis: $SuccessCount / $TotalCount" -Level $(if ($Success) { "SUCCESS" } else { "WARNING" })
    
    foreach ($Result in $TestResults) {
        $StatusColor = if ($Result.Success) { "SUCCESS" } else { "ERROR" }
        $StatusText = if ($Result.Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
        Write-Log "  $($Result.Name): $StatusText" -Level $StatusColor
        
        if (-not $Result.Success) {
            Write-Log "    Erreur: $($Result.Error)" -Level "ERROR"
        }
    }
    
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    # DÃ©terminer si le test est rÃ©ussi
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Tous les tests ont rÃ©ussi" -Level "SUCCESS"
        Write-Log "La Phase 4 a rÃ©ussi" -Level "SUCCESS"
        return $true
    } elseif ($Success) {
        Write-Log "La plupart des tests ont rÃ©ussi" -Level "WARNING"
        Write-Log "La Phase 4 a partiellement rÃ©ussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des tests ont Ã©chouÃ©" -Level "ERROR"
        Write-Log "La Phase 4 n'a pas rÃ©ussi" -Level "ERROR"
        return $false
    }
}

# ExÃ©cuter le test
$Success = Test-ScriptManager -Path $Path -OutputPath $OutputPath -Verbose:$Verbose

# Retourner le rÃ©sultat
return $Success

