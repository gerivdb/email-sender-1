# RoadmapModule.psm1
# Module commun pour les scripts de gestion de roadmap
# Version: 1.0
# Date: 2025-05-02

# Configuration
$script:LogsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\logs"

# Créer le répertoire de logs s'il n'existe pas
if (-not (Test-Path -Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

# Fonction de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor White }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
        "Debug" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier de log
    $logFile = Join-Path -Path $script:LogsPath -ChildPath "roadmap_$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

# Fonction pour vérifier si un fichier existe
function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le fichier n'existe pas: $FilePath"
    )
    
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Log -Message $ErrorMessage -Level Error
        return $false
    }
    
    return $true
}

# Fonction pour vérifier si un répertoire existe
function Test-DirectoryExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Create,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le répertoire n'existe pas: $DirectoryPath"
    )
    
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        if ($Create) {
            try {
                New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
                Write-Log -Message "Répertoire créé: $DirectoryPath" -Level Info
                return $true
            } catch {
                Write-Log -Message "Impossible de créer le répertoire: $DirectoryPath. Erreur: $_" -Level Error
                return $false
            }
        } else {
            Write-Log -Message $ErrorMessage -Level Error
            return $false
        }
    }
    
    return $true
}

# Fonction pour extraire les tâches d'un fichier markdown
function Get-RoadmapTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-FileExists -FilePath $FilePath)) {
        return $null
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $tasks = New-Object System.Collections.ArrayList
    
    # Expression régulière pour extraire les tâches
    $taskRegex = '- \[([ x])\] \*\*([0-9.]+)\*\* (.*)'
    
    $matches = [regex]::Matches($content, $taskRegex)
    
    foreach ($match in $matches) {
        $status = if ($match.Groups[1].Value -eq 'x') { 'Completed' } else { 'Pending' }
        $id = $match.Groups[2].Value
        $description = $match.Groups[3].Value.Trim()
        
        $task = [PSCustomObject]@{
            TaskId = $id
            Description = $description
            Status = $status
            Level = ($id.Split('.').Count - 1)
            ParentId = if ($id -match '^(.+)\.[^.]+$') { $matches[1] } else { $null }
        }
        
        [void]$tasks.Add($task)
    }
    
    return $tasks
}

# Fonction pour mettre à jour le statut d'une tâche dans un fichier markdown
function Update-TaskStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Completed', 'Pending')]
        [string]$Status
    )
    
    if (-not (Test-FileExists -FilePath $FilePath)) {
        return $false
    }
    
    $content = Get-Content -Path $FilePath -Raw
    
    $checkbox = if ($Status -eq 'Completed') { 'x' } else { ' ' }
    $pattern = "- \[([ x])\] \*\*$([regex]::Escape($TaskId))\*\*"
    $replacement = "- [$checkbox] **$TaskId**"
    
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    
    if ($content -ne $newContent) {
        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8
        Write-Log -Message "Statut de la tâche $TaskId mis à jour: $Status" -Level Success
        return $true
    } else {
        Write-Log -Message "Tâche $TaskId non trouvée ou déjà dans l'état $Status" -Level Warning
        return $false
    }
}

# Fonction pour convertir une tâche en vecteur
function ConvertTo-TaskVector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Task,
        
        [Parameter(Mandatory = $false)]
        [int]$VectorDimension = 1536
    )
    
    # Génération d'un vecteur aléatoire (pour les tests)
    $vector = New-Object double[] $VectorDimension
    $random = New-Object System.Random
    
    for ($i = 0; $i -lt $VectorDimension; $i++) {
        $vector[$i] = $random.NextDouble()
    }
    
    # Normaliser le vecteur
    $magnitude = [Math]::Sqrt(($vector | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)
    for ($i = 0; $i -lt $VectorDimension; $i++) {
        $vector[$i] = $vector[$i] / $magnitude
    }
    
    return $vector
}

# Exporter les fonctions
Export-ModuleMember -Function Write-Log, Test-FileExists, Test-DirectoryExists, Get-RoadmapTasks, Update-TaskStatus, ConvertTo-TaskVector
