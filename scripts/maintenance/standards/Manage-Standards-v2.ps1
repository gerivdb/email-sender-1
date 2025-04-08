<#
.SYNOPSIS
    Gère la standardisation des scripts selon les standards de codage définis.
.DESCRIPTION
    Ce script orchestre le processus d'analyse et de standardisation des scripts
    selon les standards de codage définis dans CodingStandards.md.
.PARAMETER Action
    Action à effectuer. Valeurs possibles: analyze, format, all.
    - analyze: Analyse la conformité des scripts aux standards.
    - format: Standardise les scripts selon les standards.
    - all: Effectue les deux actions.
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser/standardiser. Par défaut: scripts
.PARAMETER ScriptType
    Type de script à analyser/standardiser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par défaut: All
.PARAMETER Rules
    Liste des règles à appliquer. Par défaut: toutes les règles
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Manage-Standards-v2.ps1 -Action analyze
    Analyse tous les scripts dans le dossier scripts.
.EXAMPLE
    .\Manage-Standards-v2.ps1 -Action format -Path "scripts\maintenance" -ScriptType PowerShell -AutoApply
    Standardise automatiquement les scripts PowerShell dans le dossier spécifié.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("analyze", "format", "all")]
    [string]$Action,
    [string]$Path = "scripts",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    [string[]]$Rules = @(),
    [switch]$AutoApply,
    [switch]$ShowDetails
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
    $LogFile = "scripts\manager\data\standards_management.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour analyser la conformité des scripts
function Start-ComplianceAnalysis {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de l'analyse des scripts..." -Level "TITLE"
    
    $AnalyzeScript = "scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1"
    $OutputPath = "scripts\manager\data\compliance_report.json"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $AnalyzeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script d'analyse n'existe pas: $AnalyzeScript" -Level "ERROR"
        return $false
    }
    
    # Exécuter le script d'analyse
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$AnalyzeScript' -Path '$Path' -OutputPath '$OutputPath' -ScriptType '$ScriptType' $ShowDetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            
            Write-Log "Analyse terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre total de fichiers analysés: $($Report.TotalFiles)" -Level "INFO"
            Write-Log "Nombre total de problèmes trouvés: $($Report.TotalIssueCount)" -Level "INFO"
            Write-Log "  Problèmes de sévérité haute: $($Report.HighSeverityCount)" -Level "WARNING"
            Write-Log "  Problèmes de sévérité moyenne: $($Report.MediumSeverityCount)" -Level "WARNING"
            Write-Log "  Problèmes de sévérité basse: $($Report.LowSeverityCount)" -Level "INFO"
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du script d'analyse: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour standardiser les scripts
function Start-ScriptStandardization {
    param (
        [string]$Path,
        [string]$ScriptType,
        [string[]]$Rules,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de la standardisation des scripts..." -Level "TITLE"
    
    $FormatScript = "scripts\maintenance\standards\Format-Script-v2.ps1"
    $ComplianceReportPath = "scripts\manager\data\compliance_report.json"
    $OutputPath = "scripts\manager\data\standardization_report.json"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $FormatScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de standardisation n'existe pas: $FormatScript" -Level "ERROR"
        return $false
    }
    
    # Vérifier si le rapport de conformité existe
    if (-not (Test-Path -Path $ComplianceReportPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le rapport de conformité n'existe pas: $ComplianceReportPath" -Level "WARNING"
        Write-Log "Exécution de l'analyse de conformité..." -Level "INFO"
        
        $AnalysisSuccess = Start-ComplianceAnalysis -Path $Path -ScriptType $ScriptType -ShowDetails:$ShowDetails
        
        if (-not $AnalysisSuccess) {
            Write-Log "L'analyse de conformité a échoué" -Level "ERROR"
            return $false
        }
    }
    
    # Exécuter le script de standardisation
    $RulesParam = if ($Rules.Count -gt 0) { "-Rules " + ($Rules -join ",") } else { "" }
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$FormatScript' -Path '$Path' -ComplianceReportPath '$ComplianceReportPath' -OutputPath '$OutputPath' -ScriptType '$ScriptType' $RulesParam $AutoApplyParam $ShowDetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            
            Write-Log "Standardisation terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre total de fichiers traités: $($Report.TotalFiles)" -Level "INFO"
            Write-Log "Nombre total de modifications: $($Report.TotalChangeCount)" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Nombre de modifications appliquées: $($Report.AppliedChangeCount)" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les modifications, exécutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du script de standardisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-StandardsManagement {
    param (
        [string]$Action,
        [string]$Path,
        [string]$ScriptType,
        [string[]]$Rules,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "=== Gestion des standards de codage ===" -Level "TITLE"
    Write-Log "Action: $Action" -Level "INFO"
    Write-Log "Chemin: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    $Success = $true
    
    # Exécuter l'action demandée
    switch ($Action) {
        "analyze" {
            $Success = Start-ComplianceAnalysis -Path $Path -ScriptType $ScriptType -ShowDetails:$ShowDetails
        }
        "format" {
            $Success = Start-ScriptStandardization -Path $Path -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails
        }
        "all" {
            $Success = Start-ComplianceAnalysis -Path $Path -ScriptType $ScriptType -ShowDetails:$ShowDetails
            if ($Success) {
                $Success = Start-ScriptStandardization -Path $Path -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails
            }
        }
    }
    
    # Afficher un message de résultat
    if ($Success) {
        Write-Log "Opération terminée avec succès" -Level "SUCCESS"
    } else {
        Write-Log "Opération terminée avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# Exécuter la fonction principale
Start-StandardsManagement -Action $Action -Path $Path -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails
