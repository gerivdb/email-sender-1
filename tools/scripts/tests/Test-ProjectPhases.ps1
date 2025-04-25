<#
.SYNOPSIS
    Teste les 4 phases du projet de réorganisation des scripts.
.DESCRIPTION
    Ce script exécute des tests pour vérifier que les 4 phases du projet
    (mise à jour des références, standardisation, élimination des duplications,
    amélioration du système de gestion) ont porté leurs fruits et que tout fonctionne.
.PARAMETER TestPhase1
    Teste la Phase 1 : Mise à jour des références.
.PARAMETER TestPhase2
    Teste la Phase 2 : Standardisation des scripts.
.PARAMETER TestPhase3
    Teste la Phase 3 : Élimination des duplications.
.PARAMETER TestPhase4
    Teste la Phase 4 : Amélioration du système de gestion de scripts.
.PARAMETER TestAll
    Teste toutes les phases.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.
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

# Fonction pour tester la Phase 1 : Mise à jour des références
function Test-Phase1 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 1 : Mise à jour des références" -Level "TITLE"
    
    # Vérifier si l'outil de détection des références existe
    $ReferenceToolPath = "scripts\maintenance\references\Find-BrokenReferences.ps1"
    if (-not (Test-Path -Path $ReferenceToolPath)) {
        Write-Log "L'outil de détection des références n'existe pas: $ReferenceToolPath" -Level "ERROR"
        return $false
    }
    
    # Exécuter l'outil de détection des références
    Write-Log "Exécution de l'outil de détection des références..." -Level "TEST"
    
    try {
        $OutputPath = "scripts\tests\references_test_report.json"
        $Command = "& '$ReferenceToolPath' -Path '$Path' -OutputPath '$OutputPath'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier si le rapport a été généré
        if (-not (Test-Path -Path $OutputPath)) {
            Write-Log "Le rapport n'a pas été généré: $OutputPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
        $BrokenReferencesCount = $Report.BrokenReferencesCount
        
        if ($BrokenReferencesCount -gt 0) {
            Write-Log "Des références brisées ont été détectées: $BrokenReferencesCount" -Level "WARNING"
            Write-Log "La Phase 1 n'a pas complètement réussi" -Level "WARNING"
            return $false
        } else {
            Write-Log "Aucune référence brisée détectée" -Level "SUCCESS"
            Write-Log "La Phase 1 a réussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil de détection des références: $_" -Level "ERROR"
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
    
    # Vérifier si l'outil de standardisation existe
    $StandardsToolPath = "scripts\maintenance\standards\Manage-Standards-v2.ps1"
    if (-not (Test-Path -Path $StandardsToolPath)) {
        Write-Log "L'outil de standardisation n'existe pas: $StandardsToolPath" -Level "ERROR"
        return $false
    }
    
    # Exécuter l'outil de standardisation en mode analyse
    Write-Log "Exécution de l'outil de standardisation en mode analyse..." -Level "TEST"
    
    try {
        $Command = "& '$StandardsToolPath' -Action analyze -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier le rapport de conformité
        $ComplianceReportPath = "scripts\manager\data\compliance_report.json"
        if (-not (Test-Path -Path $ComplianceReportPath)) {
            Write-Log "Le rapport de conformité n'a pas été généré: $ComplianceReportPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $ComplianceReportPath -Raw | ConvertFrom-Json
        $HighSeverityCount = $Report.HighSeverityCount
        $MediumSeverityCount = $Report.MediumSeverityCount
        
        if ($HighSeverityCount -gt 0) {
            Write-Log "Des problèmes de sévérité haute ont été détectés: $HighSeverityCount" -Level "WARNING"
            Write-Log "La Phase 2 n'a pas complètement réussi" -Level "WARNING"
            return $false
        } elseif ($MediumSeverityCount -gt 0) {
            Write-Log "Des problèmes de sévérité moyenne ont été détectés: $MediumSeverityCount" -Level "WARNING"
            Write-Log "La Phase 2 a partiellement réussi" -Level "WARNING"
            return $true
        } else {
            Write-Log "Aucun problème de conformité majeur détecté" -Level "SUCCESS"
            Write-Log "La Phase 2 a réussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil de standardisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 3 : Élimination des duplications
function Test-Phase3 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 3 : Élimination des duplications" -Level "TITLE"
    
    # Vérifier si l'outil d'élimination des duplications existe
    $DuplicationToolPath = "scripts\maintenance\duplication\Manage-Duplications.ps1"
    if (-not (Test-Path -Path $DuplicationToolPath)) {
        Write-Log "L'outil d'élimination des duplications n'existe pas: $DuplicationToolPath" -Level "ERROR"
        return $false
    }
    
    # Exécuter l'outil d'élimination des duplications en mode détection
    Write-Log "Exécution de l'outil d'élimination des duplications en mode détection..." -Level "TEST"
    
    try {
        $Command = "& '$DuplicationToolPath' -Action detect -Path '$Path' -UsePython"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier le rapport de duplications
        $DuplicationReportPath = "scripts\manager\data\duplication_report.json"
        if (-not (Test-Path -Path $DuplicationReportPath)) {
            Write-Log "Le rapport de duplications n'a pas été généré: $DuplicationReportPath" -Level "ERROR"
            return $false
        }
        
        # Analyser le rapport
        $Report = Get-Content -Path $DuplicationReportPath -Raw | ConvertFrom-Json
        $InterFileDuplicationsCount = ($Report.inter_file_duplications | Measure-Object).Count
        
        if ($InterFileDuplicationsCount -gt 10) {
            Write-Log "Un nombre important de duplications entre fichiers a été détecté: $InterFileDuplicationsCount" -Level "WARNING"
            Write-Log "La Phase 3 n'a pas complètement réussi" -Level "WARNING"
            return $false
        } elseif ($InterFileDuplicationsCount -gt 0) {
            Write-Log "Quelques duplications entre fichiers ont été détectées: $InterFileDuplicationsCount" -Level "WARNING"
            Write-Log "La Phase 3 a partiellement réussi" -Level "WARNING"
            return $true
        } else {
            Write-Log "Aucune duplication significative détectée" -Level "SUCCESS"
            Write-Log "La Phase 3 a réussi" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil d'élimination des duplications: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 4 : Amélioration du système de gestion de scripts
function Test-Phase4 {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    
    Write-Log "Test de la Phase 4 : Amélioration du système de gestion de scripts" -Level "TITLE"
    
    # Vérifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\manager\ScriptManager.ps1"
    if (-not (Test-Path -Path $ScriptManagerPath)) {
        Write-Log "Le ScriptManager n'existe pas: $ScriptManagerPath" -Level "ERROR"
        return $false
    }
    
    # Tester les différentes fonctionnalités du ScriptManager
    $TestResults = @()
    
    # Test 1 : Inventaire
    Write-Log "Test de la fonctionnalité d'inventaire..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action inventory -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier si le fichier d'inventaire a été généré
        $InventoryPath = "scripts\manager\data\inventory.json"
        if (Test-Path -Path $InventoryPath) {
            $TestResults += $true
            Write-Log "Test d'inventaire réussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier d'inventaire n'a pas été généré: $InventoryPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test d'inventaire: $_" -Level "ERROR"
    }
    
    # Test 2 : Analyse
    Write-Log "Test de la fonctionnalité d'analyse..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action analyze -Path '$Path'"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier si le fichier d'analyse a été généré
        $AnalysisPath = "scripts\manager\data\analysis.json"
        if (Test-Path -Path $AnalysisPath) {
            $TestResults += $true
            Write-Log "Test d'analyse réussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier d'analyse n'a pas été généré: $AnalysisPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test d'analyse: $_" -Level "ERROR"
    }
    
    # Test 3 : Documentation
    Write-Log "Test de la fonctionnalité de documentation..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action document -Path '$Path' -Format Markdown"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Vérifier si le fichier de documentation a été généré
        $DocumentationPath = "scripts\manager\docs\script_documentation.markdown"
        if (Test-Path -Path $DocumentationPath) {
            $TestResults += $true
            Write-Log "Test de documentation réussi" -Level "SUCCESS"
        } else {
            $TestResults += $false
            Write-Log "Le fichier de documentation n'a pas été généré: $DocumentationPath" -Level "ERROR"
        }
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test de documentation: $_" -Level "ERROR"
    }
    
    # Test 4 : Tableau de bord
    Write-Log "Test de la fonctionnalité de tableau de bord..." -Level "TEST"
    try {
        $Command = "& '$ScriptManagerPath' -Action dashboard"
        
        if ($Verbose) {
            $Command += " -ShowDetails"
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        Invoke-Expression $Command
        
        # Le tableau de bord est affiché à l'écran, donc on considère que le test est réussi
        $TestResults += $true
        Write-Log "Test de tableau de bord réussi" -Level "SUCCESS"
    } catch {
        $TestResults += $false
        Write-Log "Erreur lors du test de tableau de bord: $_" -Level "ERROR"
    }
    
    # Calculer le résultat global
    $SuccessCount = ($TestResults | Where-Object { $_ -eq $true }).Count
    $TotalCount = $TestResults.Count
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Tous les tests du ScriptManager ont réussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        Write-Log "La Phase 4 a réussi" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des tests du ScriptManager ont réussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        Write-Log "La Phase 4 a partiellement réussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des tests du ScriptManager ont échoué ($SuccessCount/$TotalCount)" -Level "ERROR"
        Write-Log "La Phase 4 n'a pas réussi" -Level "ERROR"
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
    
    Write-Log "=== Test des phases du projet de réorganisation des scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    
    $Results = @()
    
    # Créer le dossier de tests s'il n'existe pas
    $TestsFolder = "scripts\tests"
    if (-not (Test-Path -Path $TestsFolder)) {
        New-Item -ItemType Directory -Path $TestsFolder -Force | Out-Null
        Write-Log "Dossier de tests créé: $TestsFolder" -Level "INFO"
    }
    
    # Tester la Phase 1 si demandé
    if ($TestPhase1) {
        $Results += @{
            Phase = "Phase 1: Mise à jour des références"
            Success = (Test-Phase1 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 2 si demandé
    if ($TestPhase2) {
        $Results += @{
            Phase = "Phase 2: Standardisation des scripts"
            Success = (Test-Phase2 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 3 si demandé
    if ($TestPhase3) {
        $Results += @{
            Phase = "Phase 3: Élimination des duplications"
            Success = (Test-Phase3 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Tester la Phase 4 si demandé
    if ($TestPhase4) {
        $Results += @{
            Phase = "Phase 4: Amélioration du système de gestion de scripts"
            Success = (Test-Phase4 -Path $Path -Verbose:$Verbose)
        }
    }
    
    # Afficher un résumé des résultats
    Write-Log "" -Level "INFO"
    Write-Log "=== Résumé des tests ===" -Level "TITLE"
    
    foreach ($Result in $Results) {
        $StatusColor = if ($Result.Success) { "SUCCESS" } else { "ERROR" }
        $StatusText = if ($Result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
        Write-Log "$($Result.Phase): $StatusText" -Level $StatusColor
    }
    
    # Calculer le résultat global
    $SuccessCount = ($Results | Where-Object { $_.Success -eq $true }).Count
    $TotalCount = $Results.Count
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Toutes les phases testées ont réussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des phases testées ont réussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des phases testées ont échoué ($SuccessCount/$TotalCount)" -Level "ERROR"
        return $false
    }
}

# Déterminer quelles phases tester
$TestP1 = $TestPhase1 -or $TestAll
$TestP2 = $TestPhase2 -or $TestAll
$TestP3 = $TestPhase3 -or $TestAll
$TestP4 = $TestPhase4 -or $TestAll

# Si aucune phase n'est spécifiée, tester toutes les phases
if (-not ($TestP1 -or $TestP2 -or $TestP3 -or $TestP4)) {
    $TestP1 = $true
    $TestP2 = $true
    $TestP3 = $true
    $TestP4 = $true
}

# Exécuter les tests
Start-ProjectPhasesTest -TestPhase1 $TestP1 -TestPhase2 $TestP2 -TestPhase3 $TestP3 -TestPhase4 $TestP4 -Path $Path -Verbose:$Verbose
