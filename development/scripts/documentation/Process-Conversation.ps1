# Process-Conversation.ps1
# Script pour analyser les fichiers de conversation et extraire les tÃ¢ches

param (
    [Parameter(Mandatory = $true)]
    [string]$ConversationFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddToRoadmap,
    
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
$taskLogPath = Join-Path -Path $scriptPath -ChildPath "tasks-log.txt"

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
    $noteParam = if ($Task.Priority -eq "high") { "-Note 'PrioritÃ©: Haute'" } else { "" }
    
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

# Fonction pour journaliser une tÃ¢che
function Write-Task {
    param (
        [hashtable]$Task,
        [string]$Status
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] CatÃ©gorie: $($Task.Category), PrioritÃ©: $($Task.Priority), Estimation: $($Task.Estimate) jours, DÃ©marrer: $($Task.Start), Statut: $Status, Description: $($Task.Description)"
    
    if (-not (Test-Path -Path $taskLogPath)) {
        New-Item -Path $taskLogPath -ItemType File -Force | Out-Null
    }
    
    Add-Content -Path $taskLogPath -Value $logEntry
}

# Lire le contenu du fichier de conversation
$conversationText = Get-Content -Path $ConversationFile -Raw

# Extraire les tÃ¢ches du texte
$tasks = Export-Tasks -Text $conversationText

# Afficher les rÃ©sultats
if ($tasks.Count -eq 0) {
    Write-Host "Aucune tÃ¢che dÃ©tectÃ©e dans la conversation."
}
else {
    Write-Host "TÃ¢ches dÃ©tectÃ©es : $($tasks.Count)"
    Write-Host ""
    
    foreach ($task in $tasks) {
        Write-Host "TÃ¢che :"
        Write-Host "  CatÃ©gorie : $($task.Category)"
        Write-Host "  PrioritÃ©  : $($task.Priority)"
        Write-Host "  Estimation: $($task.Estimate) jours"
        Write-Host "  DÃ©marrer  : $($task.Start)"
        Write-Host "  Description: $($task.Description)"
        
        # Ajouter la tÃ¢che Ã  la roadmap si demandÃ©
        if ($AddToRoadmap) {
            Write-Host "  Ajout Ã  la roadmap... " -NoNewline
            $success = Add-TaskToRoadmap -Task $task
            
            if ($success) {
                Write-Host "OK" -ForegroundColor Green
                Write-Task -Task $task -Status "AjoutÃ©e Ã  la roadmap"
            }
            else {
                Write-Host "Ã‰CHEC" -ForegroundColor Red
                Write-Task -Task $task -Status "Ã‰chec de l'ajout Ã  la roadmap"
            }
        }
        else {
            Write-Task -Task $task -Status "DÃ©tectÃ©e mais non ajoutÃ©e Ã  la roadmap"
        }
        
        Write-Host ""
    }
}

# Retourner les tÃ¢ches (utile pour les tests automatisÃ©s)
return $tasks


