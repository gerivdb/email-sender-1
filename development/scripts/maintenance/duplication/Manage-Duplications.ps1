<#
.SYNOPSIS
    Gère la détection et la fusion des duplications de code.
.DESCRIPTION
    Ce script orchestre le processus de détection des duplications de code et de fusion
    des scripts similaires. Il permet d'analyser les scripts, de générer un rapport
    de duplications et d'appliquer automatiquement les fusions.
    
    Section 8.2 - Surveillance Temps Réel:
    Inclut maintenant la surveillance en temps réel des modifications de fichiers
    avec intégration au bridge Go-PowerShell pour les événements.
    
.PARAMETER Action
    Action à effectuer. Valeurs possibles: detect, merge, all, watch.
    - detect: Détecte les duplications de code.
    - merge: Fusionne les scripts similaires.
    - all: Effectue les deux actions.
    - watch: Active la surveillance temps réel (Section 8.2).
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser. Par défaut: scripts
.PARAMETER MinimumLineCount
    Nombre minimum de lignes pour considérer une duplication. Par défaut: 5
.PARAMETER SimilarityThreshold
    Seuil de similarité (0-1) pour considérer deux blocs comme similaires. Par défaut: 0.8
.PARAMETER MinimumDuplicationCount
    Nombre minimum de duplications pour créer une fonction réutilisable. Par défaut: 2
.PARAMETER ScriptType
    Type de script à analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par défaut: All
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER Interactive
    Mode interactif pour valider chaque fusion.
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.PARAMETER UsePython
    Utilise les scripts Python pour la détection et la fusion (recommandé pour les grands projets).
.PARAMETER RealtimeBridgeUrl
    URL du bridge temps réel Go pour envoyer les événements. Par défaut: http://localhost:8080
.PARAMETER WatchExtensions
    Extensions de fichiers à surveiller en temps réel. Par défaut: .ps1,.py,.js,.ts,.go
.PARAMETER DebounceTimeMs
    Temps d'attente en millisecondes avant de traiter un événement (évite les doublons). Par défaut: 500
.EXAMPLE
    .\Manage-Duplications.ps1 -Action detect
    Détecte les duplications de code dans tous les scripts.
.EXAMPLE
    .\Manage-Duplications.ps1 -Action merge -AutoApply
    Fusionne automatiquement les scripts similaires.
.EXAMPLE
    .\Manage-Duplications.ps1 -Action all -Path "scripts\maintenance" -ScriptType PowerShell -Interactive
    Détecte les duplications et fusionne les scripts PowerShell dans le dossier spécifié en mode interactif.
.EXAMPLE
    .\Manage-Duplications.ps1 -Action watch -Path "development\scripts" -RealtimeBridgeUrl "http://localhost:8080"
    Active la surveillance temps réel des scripts avec intégration au bridge Go.
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("detect", "merge", "all", "watch")]
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
    [switch]$UsePython,
    [string]$RealtimeBridgeUrl = "http://localhost:8080",
    [string]$WatchExtensions = ".ps1,.py,.js,.ts,.go,.md,.yml,.json",
    [int]$DebounceTimeMs = 500
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
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "TITLE"   = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\\mode-manager\data\duplication_management.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour détecter les duplications de code avec PowerShell
function Start-DuplicationDetectionPS {
    param (
        [string]$Path,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de la détection des duplications de code avec PowerShell..." -Level "TITLE"
    
    $DetectScript = "scripts\maintenance\duplication\Find-CodeDuplication.ps1"
    $OutputPath = "scripts\\mode-manager\data\duplication_report.json"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $DetectScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de détection n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de détection
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$DetectScript' -Path '$Path' -OutputPath '$OutputPath' -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType '$ScriptType' $ShowDetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $IntraFileCount = ($Report.IntraFileDuplications | Measure-Object -Property Duplications -Sum).Sum
            $InterFileCount = $Report.InterFileDuplications.Count
            
            Write-Log "Détection terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de duplications internes trouvées: $IntraFileCount" -Level "INFO"
            Write-Log "Nombre de duplications entre fichiers trouvées: $InterFileCount" -Level "INFO"
            
            return $true
        }
        else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution du script de détection: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour détecter les duplications de code avec Python
function Start-DuplicationDetectionPY {
    param (
        [string]$Path,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de la détection des duplications de code avec Python..." -Level "TITLE"
    
    $DetectScript = "scripts\maintenance\duplication\Find-CodeDuplication.py"
    $OutputPath = "scripts\\mode-manager\data\duplication_report.json"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $DetectScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de détection Python n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }
    
    # Vérifier si Python est installé
    try {
        $PythonVersion = python --version
        Write-Log "Python détecté: $PythonVersion" -Level "INFO"
    }
    catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH" -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de détection
    $ShowDetailsParam = if ($ShowDetails) { "--details" } else { "" }
    $Command = "python '$DetectScript' --path '$Path' --output '$OutputPath' --min-lines $MinimumLineCount --similarity $SimilarityThreshold --script-type '$ScriptType' $ShowDetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $IntraFileCount = ($Report.intra_file_duplications | Measure-Object).Count
            $InterFileCount = ($Report.inter_file_duplications | Measure-Object).Count
            
            Write-Log "Détection terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de duplications internes trouvées: $IntraFileCount" -Level "INFO"
            Write-Log "Nombre de duplications entre fichiers trouvées: $InterFileCount" -Level "INFO"
            
            return $true
        }
        else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution du script de détection Python: $_" -Level "ERROR"
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
    
    Write-Log "Démarrage de la fusion des scripts similaires avec PowerShell..." -Level "TITLE"
    
    $MergeScript = "scripts\maintenance\duplication\Merge-SimilarScripts.ps1"
    $InputPath = "scripts\\mode-manager\data\duplication_report.json"
    $OutputPath = "scripts\\mode-manager\data\merge_report.json"
    $LibraryPath = "scripts\common\lib"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $MergeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de fusion n'existe pas: $MergeScript" -Level "ERROR"
        return $false
    }
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrée n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "Exécutez d'abord l'action 'detect' pour générer le rapport." -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de fusion
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $ShowDetailsParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$MergeScript' -InputPath '$InputPath' -OutputPath '$OutputPath' -LibraryPath '$LibraryPath' -MinimumDuplicationCount $MinimumDuplicationCount $AutoApplyParam $ShowDetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $MergeCount = $Report.TotalMerges
            
            Write-Log "Fusion terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de fusions: $MergeCount" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Fusions appliquées" -Level "SUCCESS"
            }
            else {
                Write-Log "Pour appliquer les fusions, exécutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        }
        else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution du script de fusion: $_" -Level "ERROR"
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
    
    Write-Log "Démarrage de la fusion des scripts similaires avec Python..." -Level "TITLE"
    
    $MergeScript = "scripts\maintenance\duplication\Merge-SimilarScripts.py"
    $InputPath = "scripts\\mode-manager\data\duplication_report.json"
    $OutputPath = "scripts\\mode-manager\data\merge_report.json"
    $LibraryPath = "scripts\common\lib"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $MergeScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de fusion Python n'existe pas: $MergeScript" -Level "ERROR"
        return $false
    }
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrée n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "Exécutez d'abord l'action 'detect' pour générer le rapport." -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de fusion
    $ApplyParam = if ($AutoApply) { "--apply" } else { "" }
    $InteractiveParam = if ($Interactive) { "--interactive" } else { "" }
    $DetailsParam = if ($ShowDetails) { "--details" } else { "" }
    $Command = "python '$MergeScript' --input '$InputPath' --output '$OutputPath' --library '$LibraryPath' --min-duplications $MinimumDuplicationCount $ApplyParam $InteractiveParam $DetailsParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $MergeCount = $Report.total_merges
            
            Write-Log "Fusion terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de fusions: $MergeCount" -Level "INFO"
            
            if ($AutoApply) {
                Write-Log "Fusions appliquées" -Level "SUCCESS"
            }
            else {
                Write-Log "Pour appliquer les fusions, exécutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        }
        else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution du script de fusion Python: $_" -Level "ERROR"
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
    Write-Log "Seuil de similarité: $SimilarityThreshold" -Level "INFO"
    Write-Log "Nombre minimum de duplications: $MinimumDuplicationCount" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    Write-Log "Utiliser Python: $UsePython" -Level "INFO"
    
    $Success = $true
    
    # Exécuter l'action demandée
    switch ($Action) {
        "detect" {
            if ($UsePython) {
                $Success = Start-DuplicationDetectionPY -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
            }
            else {
                $Success = Start-DuplicationDetectionPS -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
            }
        }
        "merge" {
            if ($UsePython) {
                $Success = Start-ScriptMergePY -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
            }
            else {
                $Success = Start-ScriptMergePS -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
            }
        }
        "all" {
            if ($UsePython) {
                $Success = Start-DuplicationDetectionPY -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
                if ($Success) {
                    $Success = Start-ScriptMergePY -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
                }
            }
            else {
                $Success = Start-DuplicationDetectionPS -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
                if ($Success) {
                    $Success = Start-ScriptMergePS -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails
                }
            }
        }
        "watch" {
            # Section 8.2 - Surveillance Temps Réel
            Write-Log "Activation de la surveillance temps réel (Section 8.2)" -Level "TITLE"
            Start-RealtimeWatching -Path $Path -RealtimeBridgeUrl $RealtimeBridgeUrl -WatchExtensions $WatchExtensions -DebounceTimeMs $DebounceTimeMs
            $Success = $true
        }
    }
    
    # Afficher un message de résultat
    if ($Success) {
        Write-Log "Opération terminée avec succès" -Level "SUCCESS"
    }
    else {
        Write-Log "Opération terminée avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# Section 8.2 - Surveillance Temps Réel
# Variables globales pour la surveillance
$script:RealtimeWatcher = $null
$script:DebounceTimers = @{
}
$script:EventQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
$script:ProcessingRunspace = $null

# Fonction pour envoyer un événement au bridge Go
function Send-EventToBridge {
    param (
        [string]$EventType,
        [string]$FilePath,
        [string]$Details,
        [string]$Severity = "medium"
    )
    
    try {
        $eventData = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            type      = $EventType
            source    = "Manage-Duplications.ps1"
            file_path = $FilePath
            details   = $Details
            severity  = $Severity
            metadata  = @{
                script_type   = Get-ScriptType -FilePath $FilePath
                file_size     = if (Test-Path $FilePath) { (Get-Item $FilePath).Length } else { 0 }
                last_modified = if (Test-Path $FilePath) { (Get-Item $FilePath).LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { $null }
            }
        } | ConvertTo-Json -Depth 10
        
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent'   = 'PowerShell-DuplicationManager/1.0'
        }
        
        Write-Log "Envoi d'événement au bridge: $EventType pour $FilePath" -Level "INFO"
        
        $response = Invoke-RestMethod -Uri "$RealtimeBridgeUrl/events" -Method POST -Body $eventData -Headers $headers -TimeoutSec 5
        
        if ($response) {
            Write-Log "Événement envoyé avec succès: $($response.status)" -Level "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Erreur lors de l'envoi d'événement au bridge: $($_.Exception.Message)" -Level "WARNING"
        return $false
    }
}

# Fonction pour déterminer le type de script
function Get-ScriptType {
    param([string]$FilePath)
    
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    switch ($extension) {
        ".ps1" { return "powershell" }
        ".psm1" { return "powershell" }
        ".py" { return "python" }
        ".js" { return "javascript" }
        ".ts" { return "typescript" }
        ".go" { return "go" }
        ".md" { return "markdown" }
        ".yml" { return "yaml" }
        ".yaml" { return "yaml" }
        ".json" { return "json" }
        default { return "unknown" }
    }
}

# Fonction pour traiter les événements de fichiers avec debouncing
function Invoke-FileChangeEvent {
    param(
        [string]$FilePath,
        [string]$ChangeType
    )
    
    # Vérifier si le fichier a une extension surveillée
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $watchExtensions = $WatchExtensions.Split(',') | ForEach-Object { $_.Trim() }
    
    if ($extension -notin $watchExtensions) {
        return
    }
    
    # Annuler le timer existant s'il y en a un
    if ($script:DebounceTimers.ContainsKey($FilePath)) {
        $script:DebounceTimers[$FilePath].Stop()
        $script:DebounceTimers[$FilePath].Dispose()
        $script:DebounceTimers.Remove($FilePath)
    }
    
    # Créer un nouveau timer pour le debouncing
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $DebounceTimeMs
    $timer.AutoReset = $false
    
    # Action à exécuter après le délai
    $action = {
        try {
            Write-Log "Traitement de la modification: $FilePath ($ChangeType)" -Level "INFO"
            
            # Analyser le fichier pour les duplications si c'est un script
            $scriptType = Get-ScriptType -FilePath $FilePath
            if ($scriptType -in @("powershell", "python", "javascript", "typescript", "go")) {
                
                # Lancer une détection rapide sur ce fichier
                $tempReport = "temp_realtime_detection_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                
                try {
                    # Utiliser PowerShell pour une détection rapide
                    $DetectScript = "development\scripts\maintenance\duplication\Find-CodeDuplication.ps1"
                    if (Test-Path $DetectScript) {
                        & $DetectScript -Path (Split-Path $FilePath -Parent) -OutputPath $tempReport -MinimumLineCount 3 -SimilarityThreshold 0.9 -ScriptType "All" -Silent
                        
                        if (Test-Path $tempReport) {
                            $report = Get-Content $tempReport -Raw | ConvertFrom-Json
                            
                            # Analyser les résultats pour ce fichier spécifique
                            $fileDuplications = @()
                            
                            # Vérifier les duplications internes
                            $intraFile = $report.IntraFileDuplications | Where-Object { $_.FilePath -eq $FilePath }
                            if ($intraFile -and $intraFile.Duplications -gt 0) {
                                $fileDuplications += "Duplications internes: $($intraFile.Duplications)"
                            }
                            
                            # Vérifier les duplications entre fichiers
                            $interFile = $report.InterFileDuplications | Where-Object { 
                                $_.File1 -eq $FilePath -or $_.File2 -eq $FilePath 
                            }
                            if ($interFile) {
                                $fileDuplications += "Duplications externes: $($interFile.Count)"
                            }
                            
                            if ($fileDuplications.Count -gt 0) {
                                $details = $fileDuplications -join "; "
                                $severity = if ($fileDuplications.Count -gt 2) { "high" } else { "medium" }
                                
                                # Envoyer l'alerte de duplication au bridge
                                Send-EventToBridge -EventType "duplication_alert" -FilePath $FilePath -Details $details -Severity $severity
                            }
                            
                            # Nettoyer le fichier temporaire
                            Remove-Item $tempReport -ErrorAction SilentlyContinue
                        }
                    }
                }
                catch {
                    Write-Log "Erreur lors de l'analyse de duplication: $($_.Exception.Message)" -Level "WARNING"
                }
            }
            
            # Envoyer l'événement de changement de fichier
            $details = "Fichier $ChangeType - Type: $scriptType"
            Send-EventToBridge -EventType "file_change" -FilePath $FilePath -Details $details -Severity "low"
            
        }
        catch {
            Write-Log "Erreur lors du traitement de l'événement: $($_.Exception.Message)" -Level "ERROR"
            Send-EventToBridge -EventType "error_detected" -FilePath $FilePath -Details "Erreur de traitement: $($_.Exception.Message)" -Severity "high"
        }
        finally {
            # Nettoyer le timer
            if ($script:DebounceTimers.ContainsKey($FilePath)) {
                $script:DebounceTimers.Remove($FilePath)
            }
        }
    }
    # Configurer le gestionnaire d'événement du timer
    $timer.Elapsed.Add({
            param($timerSender, $timerEvent)
            try {
                & $action
            }
            finally {
                $timerSender.Dispose()
            }
        })
    
    # Démarrer le timer
    $script:DebounceTimers[$FilePath] = $timer
    $timer.Start()
}

# Fonction pour démarrer la surveillance temps réel
function Start-RealtimeWatching {
    param (
        [string]$Path,
        [string]$RealtimeBridgeUrl,
        [string]$WatchExtensions,
        [int]$DebounceTimeMs
    )
    
    Write-Log "Démarrage de la surveillance temps réel..." -Level "TITLE"
    Write-Log "Chemin surveillé: $Path" -Level "INFO"
    Write-Log "Bridge URL: $RealtimeBridgeUrl" -Level "INFO"
    Write-Log "Extensions surveillées: $WatchExtensions" -Level "INFO"
    
    # Vérifier la connectivité au bridge
    try {
        $healthCheck = Invoke-RestMethod -Uri "$RealtimeBridgeUrl/health" -Method GET -TimeoutSec 5
        Write-Log "Bridge détecté et opérationnel: $($healthCheck.status)" -Level "SUCCESS"
    }
    catch {
        Write-Log "Attention: Bridge non disponible à $RealtimeBridgeUrl. Surveillance locale uniquement." -Level "WARNING"
    }
    
    # Créer le FileSystemWatcher
    $script:RealtimeWatcher = New-Object System.IO.FileSystemWatcher
    $script:RealtimeWatcher.Path = $Path
    $script:RealtimeWatcher.IncludeSubdirectories = $true
    $script:RealtimeWatcher.EnableRaisingEvents = $true
    
    # Configurer les filtres pour les extensions surveillées
    $script:RealtimeWatcher.Filter = "*.*"
    # Enregistrer les gestionnaires d'événements
    $script:EventHandlers = @()
    
    $script:EventHandlers += Register-ObjectEvent -InputObject $script:RealtimeWatcher -EventName Changed -Action {
        $filePath = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType
        Invoke-FileChangeEvent -FilePath $filePath -ChangeType $changeType
    }
    
    $script:EventHandlers += Register-ObjectEvent -InputObject $script:RealtimeWatcher -EventName Created -Action {
        $filePath = $Event.SourceEventArgs.FullPath
        Invoke-FileChangeEvent -FilePath $filePath -ChangeType "Created"
    }
    
    $script:EventHandlers += Register-ObjectEvent -InputObject $script:RealtimeWatcher -EventName Deleted -Action {
        $filePath = $Event.SourceEventArgs.FullPath
        Invoke-FileChangeEvent -FilePath $filePath -ChangeType "Deleted"
    }
    
    $script:EventHandlers += Register-ObjectEvent -InputObject $script:RealtimeWatcher -EventName Renamed -Action {
        $filePath = $Event.SourceEventArgs.FullPath
        $oldPath = $Event.SourceEventArgs.OldFullPath
        Invoke-FileChangeEvent -FilePath $filePath -ChangeType "Renamed"
        # Envoyer aussi un événement pour l'ancien fichier
        Send-EventToBridge -EventType "file_change" -FilePath $oldPath -Details "Fichier renommé vers $filePath" -Severity "low"
    }
    
    Write-Log "Surveillance temps réel active. Appuyez sur Ctrl+C pour arrêter." -Level "SUCCESS"
    
    # Envoyer un événement de démarrage
    Send-EventToBridge -EventType "monitoring_started" -FilePath $Path -Details "Surveillance démarrée pour les extensions: $WatchExtensions" -Severity "low"
    
    try {
        # Boucle infinie pour maintenir la surveillance
        while ($true) {
            Start-Sleep -Seconds 5
            
            # Vérifier périodiquement la santé du bridge
            try {
                $status = Invoke-RestMethod -Uri "$RealtimeBridgeUrl/status" -Method GET -TimeoutSec 2
                if ($status -and $status.events_processed) {
                    Write-Log "Bridge actif - Événements traités: $($status.events_processed)" -Level "INFO"
                }
            }
            catch {
                # Erreur silencieuse pour ne pas polluer les logs
            }
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Log "Arrêt de la surveillance demandé par l'utilisateur." -Level "INFO"
    }
    finally {
        # Nettoyer les ressources
        if ($script:RealtimeWatcher) {
            $script:RealtimeWatcher.EnableRaisingEvents = $false
            $script:RealtimeWatcher.Dispose()
            Write-Log "Surveillance temps réel arrêtée." -Level "INFO"
        }
        
        # Nettoyer les gestionnaires d'événements
        if ($script:EventHandlers) {
            foreach ($handler in $script:EventHandlers) {
                Unregister-Event -SourceIdentifier $handler.Name -ErrorAction SilentlyContinue
            }
            $script:EventHandlers.Clear()
        }
        
        # Nettoyer les timers
        foreach ($timer in $script:DebounceTimers.Values) {
            $timer.Stop()
            $timer.Dispose()
        }
        $script:DebounceTimers.Clear()
        
        # Envoyer un événement d'arrêt
        Send-EventToBridge -EventType "monitoring_stopped" -FilePath $Path -Details "Surveillance arrêtée" -Severity "low"
    }
}

# Exécuter la fonction principale
Start-DuplicationManagement -Action $Action -Path $Path -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -MinimumDuplicationCount $MinimumDuplicationCount -ScriptType $ScriptType -AutoApply:$AutoApply -Interactive:$Interactive -ShowDetails:$ShowDetails -UsePython:$UsePython

