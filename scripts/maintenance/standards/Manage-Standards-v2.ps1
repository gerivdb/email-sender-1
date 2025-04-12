<#
.SYNOPSIS
    GÃ¨re la standardisation des scripts selon les standards de codage dÃ©finis.
.DESCRIPTION
    Ce script orchestre le processus d'analyse et de standardisation des scripts
    selon les standards de codage dÃ©finis dans CodingStandards.md.
.PARAMETER Action
    Action Ã  effectuer. Valeurs possibles: analyze, format, all.
    - analyze: Analyse la conformitÃ© des scripts aux standards.
    - format: Standardise les scripts selon les standards.
    - all: Effectue les deux actions.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  analyser/standardiser. Par dÃ©faut: scripts
.PARAMETER ScriptType
    Type de script Ã  analyser/standardiser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER Rules
    Liste des rÃ¨gles Ã  appliquer. Par dÃ©faut: toutes les rÃ¨gles
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Manage-Standards-v2.ps1 -Action analyze
    Analyse tous les scripts dans le dossier scripts.
.EXAMPLE
    .\Manage-Standards-v2.ps1 -Action format -Path "scripts\maintenance" -ScriptType PowerShell -AutoApply
    Standardise automatiquement les scripts PowerShell dans le dossier spÃ©cifiÃ©.
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
    $LogFile = "scripts\manager\data\standards_management.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour analyser la conformitÃ© des scripts
function Start-ComplianceAnalysis {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de l'analyse des scripts..." -Level "TITLE"
    
    $AnalyzeScript = "scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1"
    $OutputPath = "scripts\manager\data\compliance_report.json"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $AnalyzeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script d'analyse n'existe pas: $AnalyzeScript" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter le script d'analyse
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$AnalyzeScript' -Path '$Path' -OutputPath '$OutputPath' -ScriptType '$ScriptType' $ShowDetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            
            Write-Log "Analyse terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre total de fichiers analysÃ©s: $($Report.TotalFiles)" -Level "INFO"
            Write-Log "Nombre total de problÃ¨mes trouvÃ©s: $($Report.TotalIssueCount)" -Level "INFO"
            Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© haute: $($Report.HighSeverityCount)" -Level "WARNING"
            Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© moyenne: $($Report.MediumSeverityCount)" -Level "WARNING"
            Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© basse: $($Report.LowSeverityCount)" -Level "INFO"
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script d'analyse: $_" -Level "ERROR"
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
    
    Write-Log "DÃ©marrage de la standardisation des scripts..." -Level "TITLE"
    
    $FormatScript = "scripts\maintenance\standards\Format-Script-v2.ps1"
    $ComplianceReportPath = "scripts\manager\data\compliance_report.json"
    $OutputPath = "scripts\manager\data\standardization_report.json"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $FormatScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de standardisation n'existe pas: $FormatScript" -Level "ERROR"
        return $false
    }
    
    # VÃ©rifier si le rapport de conformitÃ© existe
    if (-not (Test-Path -Path $ComplianceReportPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le rapport de conformitÃ© n'existe pas: $ComplianceReportPath" -Level "WARNING"
        Write-Log "ExÃ©cution de l'analyse de conformitÃ©..." -Level "INFO"
        
        $AnalysisSuccess = Start-ComplianceAnalysis -Path $Path -ScriptType $ScriptType -ShowDetails:$ShowDetails
        
        if (-not $AnalysisSuccess) {
            Write-Log "L'analyse de conformitÃ© a Ã©chouÃ©" -Level "ERROR"
            return $false
        }
    }
    
    # ExÃ©cuter le script de standardisation
    $RulesParam = if ($Rules.Count -gt 0) { "-Rules " + ($Rules -join ",") } else { "" }
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$FormatScript' -Path '$Path' -ComplianceReportPath '$ComplianceReportPath' -OutputPath '$OutputPath' -ScriptType '$ScriptType' $RulesParam $AutoApplyParam $ShowDetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            
            Write-Log "Standardisation terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre total de fichiers traitÃ©s: $($Report.TotalFiles)" -Level "INFO"
            Write-Log "Nombre total de modifications: $($Report.TotalChangeCount)" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Nombre de modifications appliquÃ©es: $($Report.AppliedChangeCount)" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les modifications, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de standardisation: $_" -Level "ERROR"
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
    
    # ExÃ©cuter l'action demandÃ©e
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
    
    # Afficher un message de rÃ©sultat
    if ($Success) {
        Write-Log "OpÃ©ration terminÃ©e avec succÃ¨s" -Level "SUCCESS"
    } else {
        Write-Log "OpÃ©ration terminÃ©e avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# ExÃ©cuter la fonction principale
Start-StandardsManagement -Action $Action -Path $Path -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails
