# Post-Conversation-Hook.ps1
# Script Ã  exÃ©cuter aprÃ¨s chaque conversation pour dÃ©tecter et traiter les tÃ¢ches

param (
    [Parameter(Mandatory = $true)]
    [string]$ConversationFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoConfirm,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# VÃ©rifier que le fichier de conversation existe
if (-not (Test-Path -Path $ConversationFile)) {
    Write-Error "Le fichier de conversation '$ConversationFile' n'existe pas."
    exit 1
}

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$processConversationPath = Join-Path -Path $scriptPath -ChildPath "Process-Conversation.ps1"
$taskLogPath = Join-Path -Path $scriptPath -ChildPath "tasks-log.txt"

# VÃ©rifier que le script de traitement des conversations existe
if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $processConversationPath"
    exit 1
}

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

# Fonction pour extraire les tÃ¢ches du texte
function Export-Tasks {
    param (
        [string]$Text
    )
    
    $tasks = @()
    $pattern = '<task\s+([^>]*)>(.*?)</task>'
    $matches = [regex]::Matches($Text, $pattern, 'Singleline')
    
    foreach ($match in $matches) {
        $attributes = $match.Groups[1].Value
        $description = $match.Groups[2].Value.Trim()
        
        # Extraire les attributs
        $category = [regex]::Match($attributes, 'category="([^"]*)"').Groups[1].Value
        $priority = [regex]::Match($attributes, 'priority="([^"]*)"').Groups[1].Value
        $estimate = [regex]::Match($attributes, 'estimate="([^"]*)"').Groups[1].Value
        $start = [regex]::Match($attributes, 'start="([^"]*)"').Groups[1].Value
        
        # Valeurs par dÃ©faut
        if (-not $category) { $category = "7" }
        if (-not $priority) { $priority = "medium" }
        if (-not $estimate) { $estimate = "1-3" }
        if (-not $start) { $start = "false" }
        
        $task = @{
            Category = $category
            Priority = $priority
            Estimate = $estimate
            Start = $start -eq "true"
            Description = $description
        }
        
        $tasks += $task
    }
    
    return $tasks
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

# Fonction pour demander confirmation Ã  l'utilisateur
function Confirm-TaskAddition {
    param (
        [hashtable]$Task
    )
    
    Write-Host ""
    Write-Host "TÃ¢che dÃ©tectÃ©e :"
    Write-Host "  CatÃ©gorie : $($Task.Category)"
    Write-Host "  PrioritÃ©  : $($Task.Priority)"
    Write-Host "  Estimation: $($Task.Estimate) jours"
    Write-Host "  DÃ©marrer  : $($Task.Start)"
    Write-Host "  Description: $($Task.Description)"
    Write-Host ""
    
    $response = Read-Host "Voulez-vous ajouter cette tÃ¢che Ã  la roadmap ? (O/N)"
    
    return $response -eq "O" -or $response -eq "o"
}

# Lire le contenu du fichier de conversation
$conversationText = Get-Content -Path $ConversationFile -Raw

# Extraire les tÃ¢ches du texte
$tasks = Export-Tasks -Text $conversationText

# Traiter les tÃ¢ches
if ($tasks.Count -eq 0) {
    if ($Verbose) {
        Write-Host "Aucune tÃ¢che dÃ©tectÃ©e dans la conversation."
    }
    
    Write-Action -Action "Analyse" -Details "Aucune tÃ¢che dÃ©tectÃ©e dans le fichier $ConversationFile"
}
else {
    Write-Host "TÃ¢ches dÃ©tectÃ©es : $($tasks.Count)"
    Write-Host ""
    
    Write-Action -Action "Analyse" -Details "$($tasks.Count) tÃ¢ches dÃ©tectÃ©es dans le fichier $ConversationFile"
    
    foreach ($task in $tasks) {
        $addTask = $AutoConfirm -or (Confirm-TaskAddition -Task $task)
        
        if ($addTask) {
            Write-Host "Ajout de la tÃ¢che Ã  la roadmap... " -NoNewline
            $success = Add-TaskToRoadmap -Task $task
            
            if ($success) {
                Write-Host "OK" -ForegroundColor Green
                Write-Action -Action "Ajout" -Details "TÃ¢che ajoutÃ©e Ã  la roadmap : $($task.Description)"
            }
            else {
                Write-Host "Ã‰CHEC" -ForegroundColor Red
                Write-Action -Action "Erreur" -Details "Ã‰chec de l'ajout de la tÃ¢che Ã  la roadmap : $($task.Description)"
            }
        }
        else {
            Write-Host "TÃ¢che ignorÃ©e." -ForegroundColor Yellow
            Write-Action -Action "IgnorÃ©" -Details "TÃ¢che ignorÃ©e par l'utilisateur : $($task.Description)"
        }
        
        Write-Host ""
    }
}

# Retourner les tÃ¢ches (utile pour les tests automatisÃ©s)
return $tasks


