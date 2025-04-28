#Requires -Version 5.1
<#
.SYNOPSIS
    Valide les workflows n8n pour dÃ©tecter les cycles.
.DESCRIPTION
    Ce script analyse les workflows n8n pour dÃ©tecter les cycles qui pourraient
    causer des boucles infinies ou des erreurs rÃ©cursives.
.PARAMETER WorkflowsPath
    Chemin du dossier contenant les workflows n8n.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER FixCycles
    Tente de corriger automatiquement les cycles dÃ©tectÃ©s.
.EXAMPLE
    .\Validate-WorkflowCycles.ps1 -WorkflowsPath ".\workflows" -OutputPath ".\reports\workflow_cycles.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkflowsPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\workflow_cycles.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$FixCycles
)

# Importer le module de dÃ©tection de cycles
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\" -Resolve
$modulePath = Join-Path -Path $modulePath -ChildPath "modules\CycleDetector.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de dÃ©tection de cycles introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour tenter de corriger un cycle dans un workflow
function Repair-WorkflowCycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory = $true)]
        [array]$Cycle
    )
    
    try {
        # Charger le workflow
        $workflow = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json
        
        # Identifier la connexion Ã  supprimer (derniÃ¨re connexion du cycle)
        $sourceId = $Cycle[-2]
        $targetId = $Cycle[-1]
        
        Write-Log "Tentative de correction du cycle en supprimant la connexion: $sourceId -> $targetId" -Level "WARNING"
        
        # VÃ©rifier si la connexion existe
        if (-not $workflow.connections.$sourceId) {
            Write-Log "Connexion source introuvable: $sourceId" -Level "ERROR"
            return $false
        }
        
        # Trouver et supprimer la connexion
        $connectionRemoved = $false
        
        if ($workflow.connections.$sourceId.main) {
            for ($i = 0; $i -lt $workflow.connections.$sourceId.main.Count; $i++) {
                $targets = $workflow.connections.$sourceId.main[$i]
                
                if ($targets) {
                    $newTargets = @()
                    
                    foreach ($target in $targets) {
                        if ($target.node -ne $targetId) {
                            $newTargets += $target
                        }
                        else {
                            $connectionRemoved = $true
                            Write-Log "Connexion supprimÃ©e: $sourceId -> $targetId (output $i)" -Level "SUCCESS"
                        }
                    }
                    
                    $workflow.connections.$sourceId.main[$i] = $newTargets
                }
            }
        }
        
        if (-not $connectionRemoved) {
            Write-Log "Aucune connexion trouvÃ©e Ã  supprimer: $sourceId -> $targetId" -Level "ERROR"
            return $false
        }
        
        # CrÃ©er une copie de sauvegarde du workflow
        $backupPath = "$WorkflowPath.bak"
        Copy-Item -Path $WorkflowPath -Destination $backupPath -Force
        
        # Enregistrer le workflow modifiÃ©
        $workflow | ConvertTo-Json -Depth 10 | Out-File -FilePath $WorkflowPath -Encoding utf8
        
        Write-Log "Workflow corrigÃ© et enregistrÃ©: $WorkflowPath (sauvegarde: $backupPath)" -Level "SUCCESS"
        
        return $true
    }
    catch {
        Write-Log "Erreur lors de la correction du cycle: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-WorkflowCycleValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowsPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$FixCycles
    )
    
    Write-Log "DÃ©marrage de la validation des cycles dans les workflows n8n..." -Level "TITLE"
    Write-Log "Dossier des workflows: $WorkflowsPath"
    
    # VÃ©rifier si le dossier existe
    if (-not (Test-Path -Path $WorkflowsPath)) {
        Write-Log "Le dossier des workflows n'existe pas: $WorkflowsPath" -Level "ERROR"
        return
    }
    
    # Initialiser le dÃ©tecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 20
    
    # Obtenir les fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowsPath -Filter "*.json" -Recurse
    
    Write-Log "Nombre de fichiers JSON trouvÃ©s: $($workflowFiles.Count)"
    
    # Filtrer pour ne garder que les workflows n8n
    $n8nWorkflows = @()
    
    foreach ($file in $workflowFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $json = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            
            # VÃ©rifier si c'est un workflow n8n
            if ($json.nodes -and $json.connections) {
                $n8nWorkflows += $file
            }
        }
        catch {
            Write-Log "Erreur lors de l'analyse du fichier JSON: $($file.FullName)" -Level "WARNING"
        }
    }
    
    Write-Log "Nombre de workflows n8n identifiÃ©s: $($n8nWorkflows.Count)"
    
    # Analyser les workflows
    $results = @()
    
    foreach ($workflow in $n8nWorkflows) {
        Write-Log "Analyse du workflow: $($workflow.FullName)"
        
        # Tester les cycles
        $cycles = @()
        $hasCycles = $false
        
        # Obtenir les statistiques de dÃ©tection de cycles avant le test
        $statsBefore = Get-CycleDetectionStatistics
        
        # Tester le workflow
        $isValid = Test-N8nWorkflowCycles -WorkflowPath $workflow.FullName
        
        # Obtenir les statistiques de dÃ©tection de cycles aprÃ¨s le test
        $statsAfter = Get-CycleDetectionStatistics
        
        # Calculer le nombre de cycles dÃ©tectÃ©s
        $cyclesDetected = $statsAfter.TotalCycles - $statsBefore.TotalCycles
        
        if (-not $isValid) {
            $hasCycles = $true
            Write-Log "Cycles dÃ©tectÃ©s dans le workflow: $($workflow.FullName)" -Level "WARNING"
            
            # RÃ©cupÃ©rer les logs de cycles
            $cycleLogs = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\logs\cycles") -Filter "cycle_*.json" | 
                         Sort-Object -Property LastWriteTime -Descending | 
                         Select-Object -First $cyclesDetected
            
            foreach ($log in $cycleLogs) {
                try {
                    $cycleInfo = Get-Content -Path $log.FullName -Raw | ConvertFrom-Json
                    
                    if ($cycleInfo.Type -eq "N8nWorkflow") {
                        $cycles += $cycleInfo.Path
                    }
                }
                catch {
                    Write-Log "Erreur lors de la lecture du fichier de log: $($log.FullName)" -Level "WARNING"
                }
            }
            
            # Tenter de corriger les cycles si demandÃ©
            if ($FixCycles -and $cycles.Count -gt 0) {
                foreach ($cycle in $cycles) {
                    $repaired = Repair-WorkflowCycle -WorkflowPath $workflow.FullName -Cycle $cycle
                    
                    if ($repaired) {
                        Write-Log "Cycle corrigÃ© dans le workflow: $($workflow.FullName)" -Level "SUCCESS"
                    }
                    else {
                        Write-Log "Impossible de corriger le cycle dans le workflow: $($workflow.FullName)" -Level "ERROR"
                    }
                }
            }
        }
        else {
            Write-Log "Aucun cycle dÃ©tectÃ© dans le workflow: $($workflow.FullName)" -Level "SUCCESS"
        }
        
        $results += [PSCustomObject]@{
            Path = $workflow.FullName
            Name = $workflow.Name
            HasCycles = $hasCycles
            CyclesCount = $cycles.Count
            Cycles = $cycles
            Repaired = if ($FixCycles -and $hasCycles) { $true } else { $false }
        }
    }
    
    # GÃ©nÃ©rer le rapport
    if ($OutputPath) {
        $report = @{
            GeneratedAt = (Get-Date).ToString("o")
            WorkflowsPath = $WorkflowsPath
            TotalWorkflows = $n8nWorkflows.Count
            WorkflowsWithCycles = ($results | Where-Object { $_.HasCycles }).Count
            Results = $results
        }
        
        # CrÃ©er le dossier de sortie s'il n'existe pas
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
        
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer le rapport
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Log "Rapport gÃ©nÃ©rÃ©: $OutputPath" -Level "SUCCESS"
    }
    
    # Afficher le rÃ©sumÃ©
    $workflowsWithCycles = ($results | Where-Object { $_.HasCycles }).Count
    
    if ($workflowsWithCycles -eq 0) {
        Write-Log "Aucun cycle dÃ©tectÃ© dans les workflows n8n." -Level "SUCCESS"
    }
    else {
        Write-Log "$workflowsWithCycles workflows contiennent des cycles." -Level "WARNING"
    }
    
    return $results
}

# ExÃ©cuter la fonction principale
Start-WorkflowCycleValidation -WorkflowsPath $WorkflowsPath -OutputPath $OutputPath -FixCycles:$FixCycles
