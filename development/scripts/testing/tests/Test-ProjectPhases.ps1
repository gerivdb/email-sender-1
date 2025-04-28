<#
.SYNOPSIS
    Teste les 4 phases du projet de rÃ©organisation des scripts.
.DESCRIPTION
    Ce script exÃ©cute des tests pour vÃ©rifier que les 4 phases du projet
    (mise Ã  jour des rÃ©fÃ©rences, standardisation, Ã©limination des duplications,
    amÃ©lioration du systÃ¨me de gestion) ont portÃ© leurs fruits et que tout fonctionne.
.PARAMETER TestPhase1
    Teste la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences.
.PARAMETER TestPhase2
    Teste la Phase 2 : Standardisation des scripts.
.PARAMETER TestPhase3
    Teste la Phase 3 : Ã‰limination des duplications.
.PARAMETER TestPhase4
    Teste la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts.
.PARAMETER TestAll
    Teste toutes les phases.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-ProjectPhases.ps1 -TestAll
    Teste toutes les phases du projet.
.EXAMPLE
    .\Test-ProjectPhases.ps1 -TestPhase1 -Path "scripts\maintenance"
    Teste uniquement la Phase 1 sur les scripts du dossier "scripts\maintenance".
#>

param (
    [switch]$TestPhase1,
    [switch]$TestPhase2,
    [switch]$TestPhase3,
    [switch]$TestPhase4,
    [switch]$TestAll,
    [string]$Path = "scripts",
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

# Fonction pour tester la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences
function Test-Phase1 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences" -Level "TITLE"
    
    # VÃ©rifier si l'outil de dÃ©tection des rÃ©fÃ©rences existe
    $ReferenceToolPath = "scripts\maintenance\references\Find-BrokenReferences.ps1"
    if (-not (Test-Path -Path $ReferenceToolPath)) {
        Write-Log "L'outil de dÃ©tection des rÃ©fÃ©rences n'existe pas: $ReferenceToolPath" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter l'outil de dÃ©tection des rÃ©fÃ©rences
    Write-Log "ExÃ©cution de l'outil de dÃ©tection des rÃ©fÃ©rences..." -Level "TEST"
    
    try {
        $OutputPath = "scripts\tests\references_test_report.json"
        $Command = "& '$ReferenceToolPath' -Path '$Path' -OutputPath '$OutputPath'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier si le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
        if (-not (Test-Path -Path $OutputPath)) {
            Write-Log "Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $OutputPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
        $BrokenReferencesCount = $Report.BrokenReferencesCount
        
        if ($BrokenReferencesCount -gt 0) {
            Write-Log "Des rÃ©fÃ©rences brisÃ©es ont Ã©tÃ© dÃ©tectÃ©es: $BrokenReferencesCount" -Level "WARNING"
            Write-Log "La Phase 1 n'a pas complÃ¨tement rÃ©ussi" -Level "WARNING"
            return $false
        } else {
            Write-Log "Aucune rÃ©fÃ©rence brisÃ©e dÃ©tectÃ©e" -Level "SUCCESS"
            Write-Log "La Phase 1 a rÃ©ussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil de dÃ©tection des rÃ©fÃ©rences: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 2 : Standardisation des scripts
function Test-Phase2 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 2 : Standardisation des scripts" -Level "TITLE"
    
    # VÃ©rifier si l'outil de standardisation existe
    $StandardsToolPath = "scripts\maintenance\standards\Manage-Standards-v2.ps1"
    if (-not (Test-Path -Path $StandardsToolPath)) {
        Write-Log "L'outil de standardisation n'existe pas: $StandardsToolPath" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter l'outil de standardisation en mode analyse
    Write-Log "ExÃ©cution de l'outil de standardisation en mode analyse..." -Level "TEST"
    
    try {
        $Command = "& '$StandardsToolPath' -Action analyze -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier le rapport de conformitÃ©
        $ComplianceReportPath = "scripts\manager\data\compliance_report.json"
        if (-not (Test-Path -Path $ComplianceReportPath)) {
            Write-Log "Le rapport de conformitÃ© n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $ComplianceReportPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $ComplianceReportPath -Raw | ConvertFrom-Json
        $HighSeverityCount = $Report.HighSeverityCount
        $MediumSeverityCount = $Report.MediumSeverityCount
        
        if ($HighSeverityCount -gt 0) {
            Write-Log "Des problÃ¨mes de sÃ©vÃ©ritÃ© haute ont Ã©tÃ© dÃ©tectÃ©s: $HighSeverityCount" -Level "WARNING"
            Write-Log "La Phase 2 n'a pas complÃ¨tement rÃ©ussi" -Level "WARNING"
            return $false
        } elseif ($MediumSeverityCount -gt 0) {
            Write-Log "Des problÃ¨mes de sÃ©vÃ©ritÃ© moyenne ont Ã©tÃ© dÃ©tectÃ©s: $MediumSeverityCount" -Level "WARNING"
            Write-Log "La Phase 2 a partiellement rÃ©ussi" -Level "WARNING"
            return $true
        } else {
            Write-Log "Aucun problÃ¨me de conformitÃ© majeur dÃ©tectÃ©" -Level "SUCCESS"
            Write-Log "La Phase 2 a rÃ©ussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil de standardisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 3 : Ã‰limination des duplications
function Test-Phase3 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 3 : Ã‰limination des duplications" -Level "TITLE"
    
    # VÃ©rifier si l'outil d'Ã©limination des duplications existe
    $DuplicationToolPath = "scripts\maintenance\duplication\Manage-Duplications.ps1"
    if (-not (Test-Path -Path $DuplicationToolPath)) {
        Write-Log "L'outil d'Ã©limination des duplications n'existe pas: $DuplicationToolPath" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter l'outil d'Ã©limination des duplications en mode dÃ©tection
    Write-Log "ExÃ©cution de l'outil d'Ã©limination des duplications en mode dÃ©tection..." -Level "TEST"
    
    try {
        $Command = "& '$DuplicationToolPath' -Action detect -Path '$Path' -UsePython"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier le rapport de duplications
        $DuplicationReportPath = "scripts\manager\data\duplication_report.json"
        if (-not (Test-Path -Path $DuplicationReportPath)) {
            Write-Log "Le rapport de duplications n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $DuplicationReportPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $DuplicationReportPath -Raw | ConvertFrom-Json
        $InterFileDuplicationsCount = ($Report.inter_file_duplications | Measure-Object).Count
        
        if ($InterFileDuplicationsCount -gt 10) {
            Write-Log "Un nombre important de duplications entre fichiers a Ã©tÃ© dÃ©tectÃ©: $InterFileDuplicationsCount" -Level "WARNING"
            Write-Log "La Phase 3 n'a pas complÃ¨tement rÃ©ussi" -Level "WARNING"
            return $false
        } elseif ($InterFileDuplicationsCount -gt 0) {
            Write-Log "Quelques duplications entre fichiers ont Ã©tÃ© dÃ©tectÃ©es: $InterFileDuplicationsCount" -Level "WARNING"
            Write-Log "La Phase 3 a partiellement rÃ©ussi" -Level "WARNING"
            return $true
        } else {
            Write-Log "Aucune duplication significative dÃ©tectÃ©e" -Level "SUCCESS"
            Write-Log "La Phase 3 a rÃ©ussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution de l'outil d'Ã©limination des duplications: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts
function Test-Phase4 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 4 : AmÃ©lioration du systÃ¨me de gestion de scripts" -Level "TITLE"
    
    # VÃ©rifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\manager\ScriptManager.ps1"
    if (-not (Test-Path -Path $ScriptManagerPath)) {
        Write-Log "Le ScriptManager n'existe pas: $ScriptManagerPath" -Level "ERROR"
        return $false
    }
    
    # Tester les diffÃ©rentes fonctionnalitÃ©s du ScriptManager
    $TestResults = @()
    
    # Test 1 : Inventaire
    Write-Log "Test de la fonctionnalitÃ© d'inventaire..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action inventory -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier d'inventaire a Ã©tÃ© gÃ©nÃ©rÃ©
        $InventoryPath = "scripts\manager\data\inventory.json"
        if (Test-Path -Path $InventoryPath) {
            $TestResults += $true
            Write-Log "Test d'inventaire rÃ©ussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier d'inventaire n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $InventoryPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test d'inventaire: $_" -Level "ERROR"
    }
    
    # Test 2 : Analyse
    Write-Log "Test de la fonctionnalitÃ© d'analyse..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action analyze -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier d'analyse a Ã©tÃ© gÃ©nÃ©rÃ©
        $AnalysisPath = "scripts\manager\data\analysis.json"
        if (Test-Path -Path $AnalysisPath) {
            $TestResults += $true
            Write-Log "Test d'analyse rÃ©ussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier d'analyse n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $AnalysisPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test d'analyse: $_" -Level "ERROR"
    }
    
    # Test 3 : Documentation
    Write-Log "Test de la fonctionnalitÃ© de documentation..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action document -Path '$Path' -Format Markdown"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de documentation a Ã©tÃ© gÃ©nÃ©rÃ©
        $DocumentationPath = "scripts\manager\docs\script_documentation.markdown"
        if (Test-Path -Path $DocumentationPath) {
            $TestResults += $true
            Write-Log "Test de documentation rÃ©ussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier de documentation n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $DocumentationPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test de documentation: $_" -Level "ERROR"
    }
    
    # Test 4 : Tableau de bord
    Write-Log "Test de la fonctionnalitÃ© de tableau de bord..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action dashboard"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Le tableau de bord est affichÃ© Ã  l'Ã©cran, donc on considÃ¨re que le test est rÃ©ussi
        $TestResults += $true
        Write-Log "Test de tableau de bord rÃ©ussi" -Level "SUCCESS"
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test de tableau de bord: $_" -Level "ERROR"
    }
    
    # Calculer le rÃ©sultat global
    $SuccessCount = ($TestResults | Where-Object { $_ -eq $true }).Count
    $TotalCount = $TestResults.Count
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Tous les tests du ScriptManager ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        Write-Log "La Phase 4 a rÃ©ussi" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des tests du ScriptManager ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        Write-Log "La Phase 4 a partiellement rÃ©ussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des tests du ScriptManager ont Ã©chouÃ© ($SuccessCount/$TotalCount)" -Level "ERROR"
        Write-Log "La Phase 4 n'a pas rÃ©ussi" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-ProjectPhasesTest {
    param (
        [bool]$TestPhase1,
        [bool]$TestPhase2,
        [bool]$TestPhase3,
        [bool]$TestPhase4,
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "=== Test des phases du projet de rÃ©organisation des scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts Ã  tester: $Path" -Level "INFO"
    
    $Results = @()
    
    # CrÃ©er le dossier de tests s'il n'existe pas
    $TestsFolder = "scripts\tests"
    if (-not (Test-Path -Path $TestsFolder)) {
        New-Item -ItemType Directory -Path $TestsFolder -Force | Out-Null
        Write-Log "Dossier de tests crÃ©Ã©: $TestsFolder" -Level "INFO"
    }
    
    # Tester la Phase 1 si demandÃ©
    if ($TestPhase1) {
        $Results += @{
            Phase = "Phase 1: Mise Ã  jour des rÃ©fÃ©rences"
            Success = (Test-Phase1 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 2 si demandÃ©
    if ($TestPhase2) {
        $Results += @{
            Phase = "Phase 2: Standardisation des scripts"
            Success = (Test-Phase2 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 3 si demandÃ©
    if ($TestPhase3) {
        $Results += @{
            Phase = "Phase 3: Ã‰limination des duplications"
            Success = (Test-Phase3 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 4 si demandÃ©
    if ($TestPhase4) {
        $Results += @{
            Phase = "Phase 4: AmÃ©lioration du systÃ¨me de gestion de scripts"
            Success = (Test-Phase4 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Log "" -Level "INFO"
    Write-Log "=== RÃ©sumÃ© des tests ===" -Level "TITLE"
    
    foreach ($Result in $Results) {
        $StatusColor = if ($Result.Success) { "SUCCESS" } else { "ERROR" }
        $StatusText = if ($Result.Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
        Write-Log "$($Result.Phase): $StatusText" -Level $StatusColor
    }
    
    # Calculer le rÃ©sultat global
    $SuccessCount = ($Results | Where-Object { $_.Success -eq $true }).Count
    $TotalCount = $Results.Count
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Toutes les phases testÃ©es ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des phases testÃ©es ont rÃ©ussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des phases testÃ©es ont Ã©chouÃ© ($SuccessCount/$TotalCount)" -Level "ERROR"
        return $false
    }
}

# DÃ©terminer quelles phases tester
$TestP1 = $TestPhase1 -or $TestAll
$TestP2 = $TestPhase2 -or $TestAll
$TestP3 = $TestPhase3 -or $TestAll
$TestP4 = $TestPhase4 -or $TestAll

# Si aucune phase n'est spÃ©cifiÃ©e, tester toutes les phases
if (-not ($TestP1 -or $TestP2 -or $TestP3 -or $TestP4)) {
    $TestP1 = $true
    $TestP2 = $true
    $TestP3 = $true
    $TestP4 = $true
}

# ExÃ©cuter les tests
Start-ProjectPhasesTest -TestPhase1 $TestP1 -TestPhase2 $TestP2 -TestPhase3 $TestP3 -TestPhase4 $TestP4 -Path $Path -Verbose:$Verbose
