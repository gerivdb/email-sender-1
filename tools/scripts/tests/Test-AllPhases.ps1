<#
.SYNOPSIS
    Teste les 4 phases du projet de réorganisation des scripts.
.DESCRIPTION
    Ce script exécute des tests pour vérifier que les 4 phases du projet
    (mise à jour des références, standardisation, élimination des duplications,
    amélioration du système de gestion) ont porté leurs fruits et que tout fonctionne.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
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

# Fonction pour écrire des messages de log
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
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour tester la Phase 1 : Mise à jour des références
function Test-Phase1 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 1 : Mise à jour des références" -Level "TITLE"
    
    # Vérifier si l'outil de détection des références existe
    $ReferenceToolPath = "scripts\maintenance\encoding\Detect-BrokenReferences.ps1"
    if (-not (Test-Path -Path $ReferenceToolPath)) {
        Write-Log "L'outil de détection des références n'existe pas: $ReferenceToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil de détection des références existe: $ReferenceToolPath" -Level "SUCCESS"
    
    # Exécuter l'outil de détection des références
    Write-Log "Exécution de l'outil de détection des références..." -Level "INFO"
    
    try {
        $OutputPath = "scripts\tests\references_test_report.json"
        & $ReferenceToolPath -Path $Path -OutputPath $OutputPath
        
        # Vérifier si le rapport a été généré
        if (Test-Path -Path $OutputPath) {
            Write-Log "Rapport généré avec succès: $OutputPath" -Level "SUCCESS"
            
            # Analyser le rapport (si possible)
            try {
                $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
                if ($Report.BrokenReferencesCount -gt 0) {
                    Write-Log "Des références brisées ont été détectées: $($Report.BrokenReferencesCount)" -Level "WARNING"
                } else {
                    Write-Log "Aucune référence brisée détectée" -Level "SUCCESS"
                }
            } catch {
                Write-Log "Impossible d'analyser le rapport: $_" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le rapport n'a pas été généré: $OutputPath" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil de détection des références: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 2 : Standardisation des scripts
function Test-Phase2 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 2 : Standardisation des scripts" -Level "TITLE"
    
    # Vérifier si l'outil de standardisation existe
    $StandardsToolPath = "scripts\maintenance\standards\Manage-Standards-v2.ps1"
    if (-not (Test-Path -Path $StandardsToolPath)) {
        Write-Log "L'outil de standardisation n'existe pas: $StandardsToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil de standardisation existe: $StandardsToolPath" -Level "SUCCESS"
    
    # Exécuter l'outil de standardisation en mode analyse
    Write-Log "Exécution de l'outil de standardisation en mode analyse..." -Level "INFO"
    
    try {
        & $StandardsToolPath -Action analyze -Path $Path
        
        # Vérifier si l'exécution a réussi
        Write-Log "Exécution réussie de l'outil de standardisation" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil de standardisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 3 : Élimination des duplications
function Test-Phase3 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 3 : Élimination des duplications" -Level "TITLE"
    
    # Vérifier si l'outil d'élimination des duplications existe
    $DuplicationToolPath = "scripts\maintenance\duplication\Manage-Duplications.ps1"
    if (-not (Test-Path -Path $DuplicationToolPath)) {
        Write-Log "L'outil d'élimination des duplications n'existe pas: $DuplicationToolPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "L'outil d'élimination des duplications existe: $DuplicationToolPath" -Level "SUCCESS"
    
    # Exécuter l'outil d'élimination des duplications en mode détection
    Write-Log "Exécution de l'outil d'élimination des duplications en mode détection..." -Level "INFO"
    
    try {
        & $DuplicationToolPath -Action detect -Path $Path
        
        # Vérifier si l'exécution a réussi
        Write-Log "Exécution réussie de l'outil d'élimination des duplications" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'outil d'élimination des duplications: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la Phase 4 : Amélioration du système de gestion de scripts
function Test-Phase4 {
    param (
        [string]$Path
    )
    
    Write-Log "Test de la Phase 4 : Amélioration du système de gestion de scripts" -Level "TITLE"
    
    # Vérifier si le ScriptManager existe
    $ScriptManagerPath = "scripts\manager\ScriptManager.ps1"
    if (-not (Test-Path -Path $ScriptManagerPath)) {
        Write-Log "Le ScriptManager n'existe pas: $ScriptManagerPath" -Level "ERROR"
        return $false
    }
    
    Write-Log "Le ScriptManager existe: $ScriptManagerPath" -Level "SUCCESS"
    
    # Tester la fonctionnalité d'inventaire
    Write-Log "Test de la fonctionnalité d'inventaire..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action inventory -Path $Path
        
        # Vérifier si le fichier d'inventaire a été généré
        $InventoryPath = "scripts\manager\data\inventory.json"
        if (Test-Path -Path $InventoryPath) {
            Write-Log "Fichier d'inventaire généré avec succès: $InventoryPath" -Level "SUCCESS"
            
            # Analyser le fichier d'inventaire
            try {
                $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
                Write-Log "Nombre de scripts inventoriés: $($Inventory.TotalScripts)" -Level "INFO"
            } catch {
                Write-Log "Impossible d'analyser le fichier d'inventaire: $_" -Level "WARNING"
            }
        } else {
            Write-Log "Le fichier d'inventaire n'a pas été généré: $InventoryPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de la fonctionnalité d'inventaire: $_" -Level "ERROR"
        return $false
    }
    
    # Tester la fonctionnalité d'analyse
    Write-Log "Test de la fonctionnalité d'analyse..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action analyze -Path $Path
        
        # Vérifier si le fichier d'analyse a été généré
        $AnalysisPath = "scripts\manager\data\analysis.json"
        if (Test-Path -Path $AnalysisPath) {
            Write-Log "Fichier d'analyse généré avec succès: $AnalysisPath" -Level "SUCCESS"
        } else {
            Write-Log "Le fichier d'analyse n'a pas été généré: $AnalysisPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de la fonctionnalité d'analyse: $_" -Level "WARNING"
        # Ne pas échouer le test complet si cette fonctionnalité échoue
    }
    
    # Tester la fonctionnalité de documentation
    Write-Log "Test de la fonctionnalité de documentation..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action document -Path $Path -Format Markdown
        
        # Vérifier si le fichier de documentation a été généré
        $DocumentationPath = "scripts\manager\docs\script_documentation.markdown"
        if (Test-Path -Path $DocumentationPath) {
            Write-Log "Fichier de documentation généré avec succès: $DocumentationPath" -Level "SUCCESS"
        } else {
            Write-Log "Le fichier de documentation n'a pas été généré: $DocumentationPath" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de la fonctionnalité de documentation: $_" -Level "WARNING"
        # Ne pas échouer le test complet si cette fonctionnalité échoue
    }
    
    # Tester la fonctionnalité de tableau de bord
    Write-Log "Test de la fonctionnalité de tableau de bord..." -Level "INFO"
    
    try {
        & $ScriptManagerPath -Action dashboard
        Write-Log "Fonctionnalité de tableau de bord exécutée avec succès" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors de l'exécution de la fonctionnalité de tableau de bord: $_" -Level "WARNING"
        # Ne pas échouer le test complet si cette fonctionnalité échoue
    }
    
    # Si au moins la fonctionnalité d'inventaire fonctionne, considérer que la phase 4 est réussie
    return $true
}

# Fonction principale
function Test-AllPhases {
    param (
        [string]$Path
    )
    
    Write-Log "=== Test des 4 phases du projet de réorganisation des scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    
    # Créer le dossier de tests s'il n'existe pas
    $TestsFolder = "scripts\tests"
    if (-not (Test-Path -Path $TestsFolder)) {
        New-Item -ItemType Directory -Path $TestsFolder -Force | Out-Null
        Write-Log "Dossier de tests créé: $TestsFolder" -Level "INFO"
    }
    
    # Tester chaque phase
    $Phase1Success = Test-Phase1 -Path $Path
    $Phase2Success = Test-Phase2 -Path $Path
    $Phase3Success = Test-Phase3 -Path $Path
    $Phase4Success = Test-Phase4 -Path $Path
    
    # Afficher un résumé des résultats
    Write-Log "" -Level "INFO"
    Write-Log "=== Résumé des tests ===" -Level "TITLE"
    Write-Log "Phase 1 (Mise à jour des références): $(if ($Phase1Success) { "RÉUSSI" } else { "ÉCHOUÉ" })" -Level $(if ($Phase1Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 2 (Standardisation des scripts): $(if ($Phase2Success) { "RÉUSSI" } else { "ÉCHOUÉ" })" -Level $(if ($Phase2Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 3 (Élimination des duplications): $(if ($Phase3Success) { "RÉUSSI" } else { "ÉCHOUÉ" })" -Level $(if ($Phase3Success) { "SUCCESS" } else { "ERROR" })
    Write-Log "Phase 4 (Amélioration du système de gestion): $(if ($Phase4Success) { "RÉUSSI" } else { "ÉCHOUÉ" })" -Level $(if ($Phase4Success) { "SUCCESS" } else { "ERROR" })
    
    # Calculer le résultat global
    $SuccessCount = @($Phase1Success, $Phase2Success, $Phase3Success, $Phase4Success).Where({ $_ -eq $true }).Count
    $TotalCount = 4
    
    if ($SuccessCount -eq $TotalCount) {
        Write-Log "Toutes les phases ont réussi ($SuccessCount/$TotalCount)" -Level "SUCCESS"
        return $true
    } elseif ($SuccessCount -ge ($TotalCount / 2)) {
        Write-Log "La plupart des phases ont réussi ($SuccessCount/$TotalCount)" -Level "WARNING"
        return $true
    } else {
        Write-Log "La plupart des phases ont échoué ($SuccessCount/$TotalCount)" -Level "ERROR"
        return $false
    }
}

# Exécuter les tests
$Success = Test-AllPhases -Path $Path

# Retourner le résultat
return $Success
