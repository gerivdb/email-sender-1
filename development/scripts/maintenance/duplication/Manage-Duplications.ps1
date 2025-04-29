<#
.SYNOPSIS
    GÃ¨re la dÃ©tection et la fusion des duplications de code.
.DESCRIPTION
    Ce script orchestre le processus de dÃ©tection des duplications de code et de fusion
    des scripts similaires. Il permet d'analyser les scripts, de gÃ©nÃ©rer un rapport
    de duplications et d'appliquer automatiquement les fusions.
.PARAMETER Action
    Action Ã  effectuer. Valeurs possibles: detect, merge, all.
    - detect: DÃ©tecte les duplications de code.
    - merge: Fusionne les scripts similaires.
    - all: Effectue les deux actions.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER MinimumLineCount
    Nombre minimum de lignes pour considÃ©rer une duplication. Par dÃ©faut: 5
.PARAMETER SimilarityThreshold
    Seuil de similaritÃ© (0-1) pour considÃ©rer deux blocs comme similaires. Par dÃ©faut: 0.8
.PARAMETER MinimumDuplicationCount
    Nombre minimum de duplications pour crÃ©er une fonction rÃ©utilisable. Par dÃ©faut: 2
.PARAMETER ScriptType
    Type de script Ã  analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER Interactive
    Mode interactif pour valider chaque fusion.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.PARAMETER UsePython
    Utilise les scripts Python pour la dÃ©tection et la fusion (recommandÃ© pour les grands projets).
.EXAMPLE
    .\Manage-Duplications.ps1 -Action detect
    DÃ©tecte les duplications de code dans tous les scripts.
.EXAMPLE
    .\Manage-Duplications.ps1 -Action merge -AutoApply
    Fusionne automatiquement les scripts similaires.
.EXAMPLE
    .\Manage-Duplications.ps1 -Action all -Path "scripts\maintenance" -ScriptType PowerShell -Interactive
    DÃ©tecte les duplications et fusionne les scripts PowerShell dans le dossier spÃ©cifiÃ© en mode interactif.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("detect", "merge", "all")]
    [string]$Action,
    [string]$Path = "scripts",
    [int]$MinimumLineCount = 5,
    [double]$SimilarityThreshold = 0.8,
    [int]$MinimumDuplicationCount = 2,
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    [switch]$AutoApply,
    [switch]$Interactive,
    [switch]$ShowDetails,
    [switch]$UsePython
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
    $LogFile = "scripts\\mode-manager\data\duplication_management.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour dÃ©tecter les duplications de code avec PowerShell
function Start-DuplicationDetectionPS {
    param (
        [string]$Path,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la dÃ©tection des duplications de code avec PowerShell..." -Level "TITLE"
    
    $DetectScript = "scripts\maintenance\duplication\Find-CodeDuplication.ps1"
    $OutputPath = "scripts\\mode-manager\data\duplication_report.json"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $DetectScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de dÃ©tection n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter le script de dÃ©tection
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$DetectScript' -Path '$Path' -OutputPath '$OutputPath' -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType '$ScriptType' $ShowDetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $IntraFileCount = ($Report.IntraFileDuplications | Measure-Object -Property Duplications -Sum).Sum
            $InterFileCount = $Report.InterFileDuplications.Count
            
            Write-Log "DÃ©tection terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de duplications internes trouvÃ©es: $IntraFileCount" -Level "INFO"
            Write-Log "Nombre de duplications entre fichiers trouvÃ©es: $InterFileCount" -Level "INFO"
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de dÃ©tection: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour dÃ©tecter les duplications de code avec Python
function Start-DuplicationDetectionPY {
    param (
        [string]$Path,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la dÃ©tection des duplications de code avec Python..." -Level "TITLE"
    
    $DetectScript = "scripts\maintenance\duplication\Find-CodeDuplication.py"
    $OutputPath = "scripts\\mode-manager\data\duplication_report.json"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $DetectScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de dÃ©tection Python n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }
    
    # VÃ©rifier si Python est installÃ©
    try {
        $PythonVersion = python --version
        Write-Log "Python dÃ©tectÃ©: $PythonVersion" -Level "INFO"
    } catch {
        Write-Log "Python n'est pas installÃ© ou n'est pas dans le PATH" -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter le script de dÃ©tection
    $ShowDetailsParam = if ($ShowDetails) { "--details" } else { "" }
    $Command = "python '$DetectScript' --path '$Path' --output '$OutputPath' --min-lines $MinimumLineCount --similarity $SimilarityThreshold --script-type '$ScriptType' $ShowDetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $IntraFileCount = ($Report.intra_file_duplications | Measure-Object).Count
            $InterFileCount = ($Report.inter_file_duplications | Measure-Object).Count
            
            Write-Log "DÃ©tection terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de duplications internes trouvÃ©es: $IntraFileCount" -Level "INFO"
            Write-Log "Nombre de duplications entre fichiers trouvÃ©es: $InterFileCount" -Level "INFO"
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de dÃ©tection Python: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour fusionner les scripts similaires avec PowerShell
function Start-ScriptMergePS {
    param (
        [int]$MinimumDuplicationCount,
        [switch]$AutoApply,
        [switch]$Interactive,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la fusion des scripts similaires avec PowerShell..." -Level "TITLE"
    
    $MergeScript = "scripts\maintenance\duplication\Merge-SimilarScripts.ps1"
    $InputPath = "scripts\\mode-manager\data\duplication_report.json"
    $OutputPath = "scripts\\mode-manager\data\merge_report.json"
    $LibraryPath = "scripts\common\lib"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $MergeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de fusion n'existe pas: $MergeScript" -Level "ERROR"
        return $false
    }
    
    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord l'action 'detect' pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter le script de fusion
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$MergeScript' -InputPath '$InputPath' -OutputPath '$OutputPath' -LibraryPath '$LibraryPath' -MinimumDuplicationCount $MinimumDuplicationCount $AutoApplyParam $ShowDetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $MergeCount = $Report.TotalMerges
            
            Write-Log "Fusion terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de fusions: $MergeCount" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Fusions appliquÃ©es" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les fusions, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de fusion: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour fusionner les scripts similaires avec Python
function Start-ScriptMergePY {
    param (
        [int]$MinimumDuplicationCount,
        [switch]$AutoApply,
        [switch]$Interactive,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la fusion des scripts similaires avec Python..." -Level "TITLE"
    
    $MergeScript = "scripts\maintenance\duplication\Merge-SimilarScripts.py"
    $InputPath = "scripts\\mode-manager\data\duplication_report.json"
    $OutputPath = "scripts\\mode-manager\data\merge_report.json"
    $LibraryPath = "scripts\common\lib"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $MergeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de fusion Python n'existe pas: $MergeScript" -Level "ERROR"
        return $false
    }
    
    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord l'action 'detect' pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return $false
    }
    
    # ExÃ©cuter le script de fusion
    $ApplyParam = if ($AutoApply) { "--apply" } else { "" }
    $InteractiveParam = if ($Interactive) { "--interactive" } else { "" }
    $DetailsParam = if ($ShowDetails) { "--details" } else { "" }
    $Command = "python '$MergeScript' --input '$InputPath' --output '$OutputPath' --library '$LibraryPath' --min-duplications $MinimumDuplicationCount $ApplyParam $InteractiveParam $DetailsParam"
    
    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $MergeCount = $Report.total_merges
            
            Write-Log "Fusion terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de fusions: $MergeCount" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Fusions appliquÃ©es" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les fusions, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de fusion Python: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-DuplicationManagement {
    param (
        [string]$Action,
        [string]$Path,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [int]$MinimumDuplicationCount,
        [string]$ScriptType,
        [switch]$AutoApply,
        [switch]$Interactive,
        [switch]$ShowDetails,
        [switch]$UsePython
    )
    
    Write-Log "=== Gestion des duplications de code ===" -Level "TITLE"
    Write-Log "Action: $Action" -Level "INFO"
    Write-Log "Chemin: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Nombre minimum de lignes: $MinimumLineCount" -Level "INFO"
    Write-Log "Seuil de similaritÃ©: $SimilarityThreshold" -Level "INFO"
    Write-Log "Nombre minimum de duplications: $MinimumDuplicationCount" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    Write-Log "Utiliser Python: $UsePython" -Level "INFO"
    
    $Success = $true
    
    # ExÃ©cuter l'action demandÃ©e
    switch ($Action) {
        "detect" {
            if ($UsePython) {
                $Success = Start-DuplicationDetectionPY -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
            } else {
                $Success = Start-DuplicationDetectionPS -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
            }
        }
        "merge" {
            if ($UsePython) {
                $Success = Start-ScriptMergePY -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
            } else {
                $Success = Start-ScriptMergePS -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
            }
        }
        "all" {
            if ($UsePython) {
                $Success = Start-DuplicationDetectionPY -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
                if ($Success) {
                    $Success = Start-ScriptMergePY -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
                }
            } else {
                $Success = Start-DuplicationDetectionPS -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
                if ($Success) {
                    $Success = Start-ScriptMergePS -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
                }
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
Start-DuplicationManagement -Action $Action -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -MinimumDuplicationCount $MinimumDuplicationCount -ScriptType $ScriptType -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails -UsePython:$UsePython

