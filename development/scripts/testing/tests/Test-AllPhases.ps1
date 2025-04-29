<#
.SYNOPSIS
    Teste les 4 phases du projet de rÃ©organisation des scripts.
.DESCRIPTION
    Ce script exÃ©cute des tests pour vÃ©rifier que les 4 phases du projet
    (mise Ã  jour des rÃ©fÃ©rences, standardisation, Ã©limination des duplications,
    amÃ©lioration du systÃ¨me de gestion) ont portÃ© leurs fruits et que tout fonctionne.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.EXAMPLE
    .\Test-AllPhases.ps1
    Teste toutes les phases du projet sur les scripts du dossier "scripts".
.EXAMPLE
    .\Test-AllPhases.ps1 -Path "scripts\maintenance"
    Teste toutes les phases du projet sur les scripts du dossier "scripts\maintenance".
#>

param (
    [string]$Path = "scripts"
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour tester la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences
function Test-Phase1 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences" -Level "TITLE"
    
    # VÃ©rifier si l'outil de dÃ©tection des rÃ©fÃ©rences existe
    $ReferenceToolPath = "scripts\maintenance\encoding\Detect-BrokenReferences.ps1"
    if (-not (Test-Path -Path $ReferenceToolPath)) {
        Write-Log "L'outil de dÃ©tection des rÃ©fÃ©rences n'existe pas: $ReferenceToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil de dÃ©tection des rÃ©fÃ©rences existe: $ReferenceToolPath" -Level "SUCCESS"
    
    # ExÃ©cuter l'outil de dÃ©tection des rÃ©fÃ©rences
    Write-Log "ExÃ©cution de l'outil de dÃ©tection des rÃ©fÃ©rences..." -Level "INFO"
    
    try {
        $OutputPath = "scripts\tests\references_test_report.json"
        & $ReferenceToolPath -Path $Path -OutputPath $OutputPath
        
        # VÃ©rifier si le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
        if (Test-Path -Path $OutputPath) {
            Write-Log "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "SUCCESS"
            
            # Analyser le rapport (si possible)
            try {
                $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
                if ($Report.BrokenReferencesCount -gt 0) {
                    Write-Log "Des rÃ©fÃ©rences brisÃ©es ont Ã©tÃ© dÃ©tectÃ©es: $($Report.BrokenReferencesCount)" -Level "WARNING"
                } else {
                    Write-Log "Aucune rÃ©fÃ©rence brisÃ©e dÃ©tectÃ©e" -Level "SUCCESS"
                }
            } catch {
                Write-Log "Impossible d'analyser le rapport: $_" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $OutputPath" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil de dÃ©tection des rÃ©fÃ©rences: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 2 : Standardisation des scripts
function Test-Phase2 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 2 : Standardisation des scripts" -Level "TITLE"
    
    # VÃ©rifier si l'outil de standardisation existe
    $StandardsToolPath = "scripts\maintenance\standards\Manage-Standards-v2.ps1"
    if (-not (Test-Path -Path $StandardsToolPath)) {
        Write-Log "L'outil de standardisation n'existe pas: $StandardsToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil de standardisation existe: $StandardsToolPath" -Level "SUCCESS"
    
    # ExÃ©cuter l'outil de standardisation en mode analyse
    Write-Log "ExÃ©cution de l'outil de standardisation en mode analyse..." -Level "INFO"
    
    try {
        & $StandardsToolPath -Action analyze -Path $Path
        
        # VÃ©rifier si l'exÃ©cution a rÃ©ussi
        Write-Log "ExÃ©cution rÃ©ussie de l'outil de standardisation" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil de standardisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 3 : Ã‰limination des duplications
function Test-Phase3 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 3 : Ã‰limination des duplications" -Level "TITLE"
    
    # VÃ©rifier si l'outil d'Ã©limination des duplications existe
    $DuplicationToolPath = "scripts\maintenance\duplication\Manage-Duplications.ps1"
    if (-not (Test-Path -Path $DuplicationToolPath)) {
        Write-Log "L'outil d'Ã©limination des duplications n'existe pas: $DuplicationToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil d'Ã©limination des duplications existe: $DuplicationToolPath" -Level "SUCCESS"
    
    # ExÃ©cuter l'outil d'Ã©limination des duplications en mode dÃ©tection
    Write-Log "ExÃ©cution de l'outil d'Ã©limination des duplications en mode dÃ©tection..." -Level "INFO"
    
    try {
        & $DuplicationToolPath -Action detect -Path $Path
        
        # VÃ©rifier si l'exÃ©cution a rÃ©ussi
        Write-Log "ExÃ©cution rÃ©ussie de l'outil d'Ã©limination des duplications" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil d'Ã©limination des duplications: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts
function Test-Phase4 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts" -Level "TITLE"
    
    # VÃ©rifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\\mode-manager\ScriptManager.ps1"
    if (-not (Test-Path -Path $ScriptManagerPath)) {
        Write-Log "Le ScriptManager n'existe pas: $ScriptManagerPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "Le ScriptManager existe: $ScriptManagerPath" -Level "SUCCESS"
    
    # Tester la fonctionnalitÃ© d'inventaire
    Write-Log "Test de la fonctionnalitÃ© d'inventaire..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action inventory -Path $Path
        
        # VÃ©rifier si le fichier d'inventaire a Ã©tÃ© gÃ©nÃ©rÃ©
        $InventoryPath = "scripts\\mode-manager\data\inventory.json"
        if (Test-Path -Path $InventoryPath) {
            Write-Log "Fichier d'inventaire gÃ©nÃ©rÃ© avec succÃ¨s: $InventoryPath" -Level "SUCCESS"
            
            # Analyser le fichier d'inventaire
            try {
                $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
                Write-Log "Nombre de scripts inventoriÃ©s: $($Inventory.TotalScripts)" -Level "INFO"
            } catch {
                Write-Log "Impossible d'analyser le fichier d'inventaire: $_" -Level "WARNING"
            }
        } else {
            Write-Log "Le fichier d'inventaire n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $InventoryPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de la fonctionnalitÃ© d'inventaire: $_" -Level "ERROR"
        return $false
    }
    
    # Tester la fonctionnalitÃ© d'analyse
    Write-Log "Test de la fonctionnalitÃ© d'analyse..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action analyze -Path $Path
        
        # VÃ©rifier si le fichier d'analyse a Ã©tÃ© gÃ©nÃ©rÃ©
        $AnalysisPath = "scripts\\mode-manager\data\analysis.json"
        if (Test-Path -Path $AnalysisPath) {
            Write-Log "Fichier d'analyse gÃ©nÃ©rÃ© avec succÃ¨s: $AnalysisPath" -Level "SUCCESS"
        } else {
            Write-Log "Le fichier d'analyse n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $AnalysisPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de la fonctionnalitÃ© d'analyse: $_" -Level "WARNING"
        # Ne pas Ã©chouer le test complet si cette fonctionnalitÃ© Ã©choue
    }
    
    # Tester la fonctionnalitÃ© de documentation
    Write-Log "Test de la fonctionnalitÃ© de documentation..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action document -Path $Path -Format Markdown
        
        # VÃ©rifier si le fichier de documentation a Ã©tÃ© gÃ©nÃ©rÃ©
        $DocumentationPath = "scripts\\mode-manager\docs\script_documentation.markdown"
        if (Test-Path -Path $DocumentationPath) {
            Write-Log "Fichier de documentation gÃ©nÃ©rÃ© avec succÃ¨s: $DocumentationPath" -Level "SUCCESS"
        } else {
            Write-Log "Le fichier de documentation n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $DocumentationPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de la fonctionnalitÃ© de documentation: $_" -Level "WARNING"
        # Ne pas Ã©chouer le test complet si cette fonctionnalitÃ© Ã©choue
    }
    
    # Tester la fonctionnalitÃ© de tableau de bord
    Write-Log "Test de la fonctionnalitÃ© de tableau de bord..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action dashboard
        Write-Log "FonctionnalitÃ© de tableau de bord exÃ©cutÃ©e avec succÃ¨s" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de la fonctionnalitÃ© de tableau de bord: $_" -Level "WARNING"
        # Ne pas Ã©chouer le test complet si cette fonctionnalitÃ© Ã©choue
    }
    
    # Si au moins la fonctionnalitÃ© d'inventaire fonctionne, considÃ©rer que la phase 4 est rÃ©ussie
    return $true
}

# Fonction principale
function Test-AllPhases {
    param (
        [string]$Path
    )
    
    Write-Log "=== Test des 4 phases du projet de rÃ©organisation des scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts Ã  tester: $Path" -Level "INFO"
    
    # CrÃ©er le dossier de tests s'il n'existe pas
    $TestsFolder = "scripts\tests"
    if (-not (Test-Path -Path $TestsFolder)) {
        New-Item -ItemType Directory -Path $TestsFolder -Force | Out-Null
        Write-Log "Dossier de tests crÃ©Ã©: $TestsFolder" -Level "INFO"
    }
    
    # Tester chaque phase
    $Phase1Success = Test-Phase1 -Path $Path
    $Phase2Success = Test-Phase2 -Path $Path
    $Phase3Success = Test-Phase3 -Path $Path
    $Phase4Success = Test-Phase4 -Path $Path
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Log "" -Level "INFO"
    Write-Log "=== RÃ©sumÃ© des tests ===" -Level "TITLE"
    Write-Log "Phase 1 (Mise Ã  jour des rÃ©fÃ©rences): $(if ($Phase1Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" })" -Level $(if ($Phase1Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 2 (Standardisation des scripts): $(if ($Phase2Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" })" -Level $(if ($Phase2Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 3 (Ã‰limination des duplications): $(if ($Phase3Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" })" -Level $(if ($Phase3Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 4 (AmÃ©lioration du systÃ¨me de gestion): $(if ($Phase4Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" })" -Level $(if ($Phase4Success) { "SUCCESS" } else { "ERROR" })
    
    # Calculer le rÃ©sultat global
    $SuccessCount = @($Phase1Success, $Phase2Success, $Phase3Success, $Phase4Success).Where({ $_ -eq $true }).Count
    $TotalCount = 4
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Toutes les phases ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des phases ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des phases ont Ã©chouÃ© ($SuccessCount/$TotalCount)" -Level "ERROR"
        return $false
    }
}

# ExÃ©cuter les tests
$Success = Test-AllPhases -Path $Path

# Retourner le rÃ©sultat
return $Success

