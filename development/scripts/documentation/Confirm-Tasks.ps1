# Confirm-Tasks.ps1
# Script pour confirmer ou rejeter les tÃ¢ches dÃ©tectÃ©es avant de les ajouter Ã  la roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$PendingTasksFile = ".\pending-tasks.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskLogPath = Join-Path -Path $scriptPath -ChildPath "tasks-log.txt"

# Fonction pour journaliser une action
function Write-Action {
    param (
        [string]$Action,
        [string]$Details
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Action : $Details"
    
    if (-not (Test-Path -Path $taskLogPath)) {
        New-Item -Path $taskLogPath -ItemType File -Force | Out-Null
    }
    
    Add-Content -Path $taskLogPath -Value $logEntry
}

# Fonction pour ajouter une tÃ¢che Ã  la roadmap
function Add-TaskToRoadmap {
    param (
        [hashtable]$Task
    )
    
    $captureRequestPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Capture-Request-Simple.ps1"
    
    if (-not (Test-Path -Path $captureRequestPath)) {
        Write-Error "Le script Capture-Request-Simple.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $captureRequestPath"
        return $false
    }
    
    $startParam = if ($Task.Start) { "-Start" } else { "" }
    $priorityNote = switch ($Task.Priority) {
        "high" { "PRIORITAIRE" }
        "medium" { "PrioritÃ© moyenne" }
        "low" { "PrioritÃ© basse" }
        default { "" }
    }
    
    $noteParam = if ($priorityNote) { "-Note '$priorityNote'" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$captureRequestPath`" -Request `"$($Task.Description)`" -Category $($Task.Category) -EstimatedDays `"$($Task.Estimate)`" $startParam $noteParam"
    
    if ($Verbose) {
        Write-Host "ExÃ©cution de la commande : $command"
    }
    
    try {
        Invoke-Expression $command
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'ajout de la tÃ¢che Ã  la roadmap : $_"
        return $false
    }
}

# Fonction pour charger les tÃ¢ches en attente
function Import-PendingTasks {
    if (-not (Test-Path -Path $PendingTasksFile)) {
        return @()
    }
    
    try {
        $pendingTasks = Get-Content -Path $PendingTasksFile -Raw | ConvertFrom-Json
        return $pendingTasks
    }
    catch {
        Write-Error "Erreur lors du chargement des tÃ¢ches en attente : $_"
        return @()
    }
}

# Fonction pour sauvegarder les tÃ¢ches en attente
function Save-PendingTasks {
    param (
        [array]$Tasks
    )
    
    try {
        $Tasks | ConvertTo-Json -Depth 10 | Set-Content -Path $PendingTasksFile
        return $true
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde des tÃ¢ches en attente : $_"
        return $false
    }
}

# Fonction pour afficher une tÃ¢che
function Show-Task {
    param (
        [hashtable]$Task,
        [int]$Index
    )
    
    Write-Host "TÃ¢che #$Index :"
    Write-Host "  CatÃ©gorie : $($Task.Category)"
    Write-Host "  PrioritÃ©  : $($Task.Priority)"
    Write-Host "  Estimation: $($Task.Estimate) jours"
    Write-Host "  DÃ©marrer  : $($Task.Start)"
    Write-Host "  Description: $($Task.Description)"
    Write-Host ""
}

# Fonction pour confirmer une tÃ¢che
function Confirm-Task {
    param (
        [hashtable]$Task,
        [int]$Index
    )
    
    Show-Task -Task $Task -Index $Index
    
    $response = Read-Host "Que souhaitez-vous faire avec cette tÃ¢che ? (A)jouter, (M)odifier, (I)gnorer, (S)upprimer"
    
    switch ($response.ToLower()) {
        "a" {
            Write-Host "Ajout de la tÃ¢che Ã  la roadmap... " -NoNewline
            $success = Add-TaskToRoadmap -Task $Task
            
            if ($success) {
                Write-Host "OK" -ForegroundColor Green
                Write-Action -Action "Ajout" -Details "TÃ¢che ajoutÃ©e Ã  la roadmap : $($Task.Description)"
                return "added"
            }
            else {
                Write-Host "Ã‰CHEC" -ForegroundColor Red
                Write-Action -Action "Erreur" -Details "Ã‰chec de l'ajout de la tÃ¢che Ã  la roadmap : $($Task.Description)"
                return "pending"
            }
        }
        "m" {
            $Task = Set-Task -Task $Task
            return "modified"
        }
        "i" {
            Write-Host "TÃ¢che ignorÃ©e." -ForegroundColor Yellow
            Write-Action -Action "IgnorÃ©" -Details "TÃ¢che ignorÃ©e par l'utilisateur : $($Task.Description)"
            return "pending"
        }
        "s" {
            Write-Host "TÃ¢che supprimÃ©e." -ForegroundColor Yellow
            Write-Action -Action "SupprimÃ©" -Details "TÃ¢che supprimÃ©e par l'utilisateur : $($Task.Description)"
            return "deleted"
        }
        default {
            Write-Host "Option non reconnue. La tÃ¢che reste en attente." -ForegroundColor Yellow
            return "pending"
        }
    }
}

# Fonction pour modifier une tÃ¢che
function Set-Task {
    param (
        [hashtable]$Task
    )
    
    Write-Host "Modification de la tÃ¢che :"
    Write-Host ""
    
    # CatÃ©gorie
    Write-Host "CatÃ©gorie actuelle : $($Task.Category)"
    Write-Host "1. Documentation et formation"
    Write-Host "2. Gestion amÃ©liorÃ©e des rÃ©pertoires et des chemins"
    Write-Host "3. AmÃ©lioration de la compatibilitÃ© des terminaux"
    Write-Host "4. Standardisation des hooks Git"
    Write-Host "5. AmÃ©lioration de l'authentification"
    Write-Host "6. Alternatives aux serveurs MCP traditionnels"
    Write-Host "7. Demandes spontanÃ©es"
    $newCategory = Read-Host "Nouvelle catÃ©gorie (1-7, ou vide pour conserver la valeur actuelle)"
    
    if ($newCategory -match "^[1-7]$") {
        $Task.Category = $newCategory
    }
    
    # PrioritÃ©
    Write-Host "PrioritÃ© actuelle : $($Task.Priority)"
    Write-Host "1. Haute (high)"
    Write-Host "2. Moyenne (medium)"
    Write-Host "3. Basse (low)"
    $newPriority = Read-Host "Nouvelle prioritÃ© (1-3, ou vide pour conserver la valeur actuelle)"
    
    switch ($newPriority) {
        "1" { $Task.Priority = "high" }
        "2" { $Task.Priority = "medium" }
        "3" { $Task.Priority = "low" }
    }
    
    # Estimation
    Write-Host "Estimation actuelle : $($Task.Estimate) jours"
    $newEstimate = Read-Host "Nouvelle estimation (format 'X-Y' ou 'X', ou vide pour conserver la valeur actuelle)"
    
    if ($newEstimate -match "^\d+(-\d+)?$") {
        $Task.Estimate = $newEstimate
    }
    
    # DÃ©marrer
    Write-Host "DÃ©marrer immÃ©diatement : $($Task.Start)"
    $newStart = Read-Host "DÃ©marrer immÃ©diatement (O/N, ou vide pour conserver la valeur actuelle)"
    
    if ($newStart -eq "O" -or $newStart -eq "o") {
        $Task.Start = $true
    }
    elseif ($newStart -eq "N" -or $newStart -eq "n") {
        $Task.Start = $false
    }
    
    # Description
    Write-Host "Description actuelle : $($Task.Description)"
    $newDescription = Read-Host "Nouvelle description (ou vide pour conserver la valeur actuelle)"
    
    if ($newDescription) {
        $Task.Description = $newDescription
    }
    
    Write-Host ""
    Write-Host "TÃ¢che modifiÃ©e avec succÃ¨s." -ForegroundColor Green
    
    return $Task
}

# Fonction principale
function Main {
    Write-Host "Confirmation des tÃ¢ches en attente"
    Write-Host ""
    
    # Charger les tÃ¢ches en attente
    $pendingTasks = Import-PendingTasks
    
    if ($pendingTasks.Count -eq 0) {
        Write-Host "Aucune tÃ¢che en attente."
        return
    }
    
    Write-Host "TÃ¢ches en attente : $($pendingTasks.Count)"
    Write-Host ""
    
    # Traiter chaque tÃ¢che
    $updatedTasks = @()
    
    for ($i = 0; $i -lt $pendingTasks.Count; $i++) {
        $task = $pendingTasks[$i]
        $result = Confirm-Task -Task $task -Index ($i + 1)
        
        if ($result -eq "pending" -or $result -eq "modified") {
            $updatedTasks += $task
        }
    }
    
    # Sauvegarder les tÃ¢ches mises Ã  jour
    Save-PendingTasks -Tasks $updatedTasks
    
    Write-Host ""
    Write-Host "Traitement des tÃ¢ches terminÃ©."
    Write-Host "TÃ¢ches restantes en attente : $($updatedTasks.Count)"
}

# ExÃ©cuter la fonction principale
Main


