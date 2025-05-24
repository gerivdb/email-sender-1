# Integrate-TaskDetection.ps1
# Script pour intÃ©grer le systÃ¨me de dÃ©tection de tÃ¢ches avec les scripts existants de gestion de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$ConversationsFolder = ".\conversations",
    
    [Parameter(Mandatory = $false)]
    [switch]$StartWatcher,
    
    [Parameter(Mandatory = $false)]
    [switch]$ProcessExisting,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddToRoadmap,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$watchConversationsPath = Join-Path -Path $scriptPath -ChildPath "Watch-Conversations.ps1"
$processConversationPath = Join-Path -Path $scriptPath -ChildPath "Process-Conversation.ps1"
$roadmapPath = "Roadmap\roadmap_perso.md"""

# VÃ©rifier que les scripts nÃ©cessaires existent
if (-not (Test-Path -Path $watchConversationsPath)) {
    Write-Error "Le script Watch-Conversations.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $watchConversationsPath"
    exit 1
}

if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $processConversationPath"
    exit 1
}

# VÃ©rifier que le dossier de conversations existe, sinon le crÃ©er
if (-not (Test-Path -Path $ConversationsFolder)) {
    New-Item -Path $ConversationsFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de conversations crÃ©Ã© : $ConversationsFolder"
}

# Fonction pour traiter les fichiers de conversation existants
function Invoke-ExistingConversations {
    $conversationFiles = Get-ChildItem -Path $ConversationsFolder -Filter "*.txt" | Select-Object -ExpandProperty FullName
    
    if ($conversationFiles.Count -eq 0) {
        Write-Host "Aucun fichier de conversation trouvÃ© dans le dossier : $ConversationsFolder"
        return
    }
    
    Write-Host "Traitement des fichiers de conversation existants : $($conversationFiles.Count) fichiers"
    Write-Host ""
    
    foreach ($file in $conversationFiles) {
        Write-Host "Traitement du fichier : $file"
        
        $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
        $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
        
        $command = "powershell -ExecutionPolicy Bypass -File `"$processConversationPath`" -ConversationFile `"$file`" $addToRoadmapParam $verboseParam"
        
        if ($Verbose) {
            Write-Host "ExÃ©cution de la commande : $command"
        }
        
        try {
            Invoke-Expression $command
            Write-Host "Fichier traitÃ© avec succÃ¨s : $file" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors du traitement du fichier de conversation : $_"
            Write-Host "Ã‰chec du traitement du fichier : $file" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}

# Fonction pour dÃ©marrer le watcher
function Start-ConversationWatcher {
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$watchConversationsPath`" -ConversationsFolder `"$ConversationsFolder`" $addToRoadmapParam $verboseParam"
    
    if ($Verbose) {
        Write-Host "ExÃ©cution de la commande : $command"
    }
    
    try {
        Invoke-Expression $command
    }
    catch {
        Write-Error "Erreur lors du dÃ©marrage du watcher : $_"
    }
}

# Fonction pour vÃ©rifier l'Ã©tat de la roadmap
function Test-Roadmap {
    if (-not (Test-Path -Path $roadmapPath)) {
        Write-Error "Le fichier roadmap n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $roadmapPath"
        return $false
    }
    
    Write-Host "VÃ©rification de la roadmap : $roadmapPath"
    
    $roadmapContent = Get-Content -Path $roadmapPath -Raw
    
    if ($roadmapContent -match "## 7\. Demandes spontanees") {
        Write-Host "La catÃ©gorie 'Demandes spontanÃ©es' existe dans la roadmap." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "La catÃ©gorie 'Demandes spontanÃ©es' n'existe pas dans la roadmap." -ForegroundColor Yellow
        Write-Host "Vous devriez ajouter cette catÃ©gorie Ã  la roadmap pour que les demandes spontanÃ©es puissent y Ãªtre ajoutÃ©es."
        return $false
    }
}

# Fonction principale
function Main {
    Write-Host "IntÃ©gration du systÃ¨me de dÃ©tection de tÃ¢ches avec les scripts existants de gestion de roadmap"
    Write-Host ""
    
    # VÃ©rifier l'Ã©tat de la roadmap
    $roadmapOk = Test-Roadmap
    Write-Host ""
    
    # Traiter les fichiers de conversation existants si demandÃ©
    if ($ProcessExisting) {
        Invoke-ExistingConversations
    }
    
    # DÃ©marrer le watcher si demandÃ©
    if ($StartWatcher) {
        if ($roadmapOk -or $AddToRoadmap) {
            Start-ConversationWatcher
        }
        else {
            Write-Host "Le watcher n'a pas Ã©tÃ© dÃ©marrÃ© car la roadmap n'est pas correctement configurÃ©e." -ForegroundColor Yellow
            Write-Host "Ajoutez la catÃ©gorie 'Demandes spontanÃ©es' Ã  la roadmap ou utilisez le paramÃ¨tre -AddToRoadmap pour l'ajouter automatiquement."
        }
    }
}

# ExÃ©cuter la fonction principale
Main

