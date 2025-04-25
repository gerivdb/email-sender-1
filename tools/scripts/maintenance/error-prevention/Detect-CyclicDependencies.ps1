#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte les dépendances cycliques dans les scripts et workflows.
.DESCRIPTION
    Ce script analyse les scripts et workflows pour détecter les dépendances cycliques
    qui pourraient causer des boucles infinies ou des erreurs récursives.
.PARAMETER Path
    Chemin du dossier ou fichier à analyser.
.PARAMETER Recursive
    Analyse récursivement les sous-dossiers.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER IncludeWorkflows
    Inclut l'analyse des workflows n8n.
.PARAMETER MaxDepth
    Profondeur maximale pour l'analyse récursive des dépendances.
.EXAMPLE
    .\Detect-CyclicDependencies.ps1 -Path ".\scripts" -Recursive -OutputPath ".\reports\dependencies.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\dependencies.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeWorkflows,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxDepth = 5
)

# Importer le module de détection de cycles
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\" -Resolve
$modulePath = Join-Path -Path $modulePath -ChildPath "modules\CycleDetector.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de détection de cycles introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
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

# Fonction principale
function Start-CyclicDependencyDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeWorkflows,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth
    )
    
    Write-Log "Démarrage de la détection des dépendances cycliques..." -Level "TITLE"
    Write-Log "Chemin: $Path"
    Write-Log "Récursif: $Recursive"
    Write-Log "Profondeur maximale: $MaxDepth"
    Write-Log "Inclure les workflows: $IncludeWorkflows"
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le chemin n'existe pas: $Path" -Level "ERROR"
        return
    }
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth $MaxDepth
    
    # Obtenir les fichiers à analyser
    $scriptExtensions = @(".ps1", ".py", ".bat", ".cmd", ".sh")
    $workflowExtensions = @(".json")
    
    $files = @()
    
    if (Test-Path -Path $Path -PathType Container) {
        # C'est un dossier
        $searchOptions = @{
            Path = $Path
            File = $true
            Include = $scriptExtensions
        }
        
        if ($Recursive) {
            $searchOptions.Recurse = $true
        }
        
        $files += Get-ChildItem @searchOptions
        
        # Ajouter les workflows si demandé
        if ($IncludeWorkflows) {
            $workflowOptions = @{
                Path = $Path
                File = $true
                Include = $workflowExtensions
            }
            
            if ($Recursive) {
                $workflowOptions.Recurse = $true
            }
            
            $workflowFiles = Get-ChildItem @workflowOptions
            
            # Filtrer pour ne garder que les workflows n8n
            $n8nWorkflows = @()
            
            foreach ($file in $workflowFiles) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw
                    $json = ConvertFrom-Json -InputObject $content -ErrorAction Stop
                    
                    # Vérifier si c'est un workflow n8n
                    if ($json.nodes -and $json.connections) {
                        $n8nWorkflows += $file
                    }
                }
                catch {
                    Write-Log "Erreur lors de l'analyse du fichier JSON: $($file.FullName)" -Level "WARNING"
                }
            }
            
            $files += $n8nWorkflows
        }
    }
    else {
        # C'est un fichier
        $files += Get-Item -Path $Path
    }
    
    Write-Log "Nombre de fichiers à analyser: $($files.Count)"
    
    # Analyser les fichiers
    $dependencies = @{}
    $cycles = @()
    
    foreach ($file in $files) {
        $extension = [System.IO.Path]::GetExtension($file.FullName).ToLower()
        
        if ($workflowExtensions -contains $extension -and $IncludeWorkflows) {
            # Analyser le workflow n8n
            Write-Log "Analyse du workflow n8n: $($file.FullName)"
            
            $result = Test-N8nWorkflowCycles -WorkflowPath $file.FullName
            
            if (-not $result) {
                Write-Log "Cycles détectés dans le workflow: $($file.FullName)" -Level "WARNING"
            }
        }
        elseif ($scriptExtensions -contains $extension) {
            # Analyser le script
            Write-Log "Analyse du script: $($file.FullName)"
            
            $scriptDeps = Find-ScriptDependencies -ScriptPath $file.FullName -Recursive:$Recursive -MaxDepth $MaxDepth
            
            $dependencies[$file.FullName] = @{
                Path = $file.FullName
                Name = $file.Name
                Type = switch ($extension) {
                    ".ps1" { "PowerShell" }
                    ".py" { "Python" }
                    ".bat" { "Batch" }
                    ".cmd" { "Batch" }
                    ".sh" { "Shell" }
                    default { "Unknown" }
                }
                Dependencies = $scriptDeps
            }
        }
    }
    
    # Obtenir les statistiques de détection de cycles
    $stats = Get-CycleDetectionStatistics
    
    Write-Log "Nombre total de cycles détectés: $($stats.TotalCycles)" -Level $(if ($stats.TotalCycles -gt 0) { "WARNING" } else { "SUCCESS" })
    
    foreach ($type in $stats.CyclesByType.Keys) {
        Write-Log "Cycles de type '$type': $($stats.CyclesByType[$type])"
    }
    
    # Générer le rapport
    if ($OutputPath) {
        $report = @{
            GeneratedAt = (Get-Date).ToString("o")
            Path = $Path
            Recursive = $Recursive
            IncludeWorkflows = $IncludeWorkflows
            MaxDepth = $MaxDepth
            TotalFiles = $files.Count
            Dependencies = $dependencies
            CycleStatistics = $stats
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
        
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer le rapport
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Log "Rapport généré: $OutputPath" -Level "SUCCESS"
    }
    
    return $stats
}

# Exécuter la fonction principale
Start-CyclicDependencyDetection -Path $Path -Recursive:$Recursive -OutputPath $OutputPath -IncludeWorkflows:$IncludeWorkflows -MaxDepth $MaxDepth
