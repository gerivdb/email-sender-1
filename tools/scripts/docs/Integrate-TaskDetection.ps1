# Integrate-TaskDetection.ps1
# Script pour intégrer le système de détection de tâches avec les scripts existants de gestion de roadmap

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

# Vérifier que les scripts nécessaires existent
if (-not (Test-Path -Path $watchConversationsPath)) {
    Write-Error "Le script Watch-Conversations.ps1 n'a pas été trouvé à l'emplacement : $watchConversationsPath"
    exit 1
}

if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas été trouvé à l'emplacement : $processConversationPath"
    exit 1
}

# Vérifier que le dossier de conversations existe, sinon le créer
if (-not (Test-Path -Path $ConversationsFolder)) {
    New-Item -Path $ConversationsFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de conversations créé : $ConversationsFolder"
}

# Fonction pour traiter les fichiers de conversation existants
function Process-ExistingConversations {
    $conversationFiles = Get-ChildItem -Path $ConversationsFolder -Filter "*.txt" | Select-Object -ExpandProperty FullName
    
    if ($conversationFiles.Count -eq 0) {
        Write-Host "Aucun fichier de conversation trouvé dans le dossier : $ConversationsFolder"
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
            Write-Host "Exécution de la commande : $command"
        }
        
        try {
            Invoke-Expression $command
            Write-Host "Fichier traité avec succès : $file" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors du traitement du fichier de conversation : $_"
            Write-Host "Échec du traitement du fichier : $file" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}

# Fonction pour démarrer le watcher
function Start-ConversationWatcher {
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$watchConversationsPath`" -ConversationsFolder `"$ConversationsFolder`" $addToRoadmapParam $verboseParam"
    
    if ($Verbose) {
        Write-Host "Exécution de la commande : $command"
    }
    
    try {
        Invoke-Expression $command
    }
    catch {
        Write-Error "Erreur lors du démarrage du watcher : $_"
    }
}

# Fonction pour vérifier l'état de la roadmap
function Check-Roadmap {
    if (-not (Test-Path -Path $roadmapPath)) {
        Write-Error "Le fichier roadmap n'a pas été trouvé à l'emplacement : $roadmapPath"
        return $false
    }
    
    Write-Host "Vérification de la roadmap : $roadmapPath"
    
    $roadmapContent = Get-Content -Path $roadmapPath -Raw
    
    if ($roadmapContent -match "## 7\. Demandes spontanees") {
        Write-Host "La catégorie 'Demandes spontanées' existe dans la roadmap." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "La catégorie 'Demandes spontanées' n'existe pas dans la roadmap." -ForegroundColor Yellow
        Write-Host "Vous devriez ajouter cette catégorie à la roadmap pour que les demandes spontanées puissent y être ajoutées."
        return $false
    }
}

# Fonction principale
function Main {
    Write-Host "Intégration du système de détection de tâches avec les scripts existants de gestion de roadmap"
    Write-Host ""
    
    # Vérifier l'état de la roadmap
    $roadmapOk = Check-Roadmap
    Write-Host ""
    
    # Traiter les fichiers de conversation existants si demandé
    if ($ProcessExisting) {
        Process-ExistingConversations
    }
    
    # Démarrer le watcher si demandé
    if ($StartWatcher) {
        if ($roadmapOk -or $AddToRoadmap) {
            Start-ConversationWatcher
        }
        else {
            Write-Host "Le watcher n'a pas été démarré car la roadmap n'est pas correctement configurée." -ForegroundColor Yellow
            Write-Host "Ajoutez la catégorie 'Demandes spontanées' à la roadmap ou utilisez le paramètre -AddToRoadmap pour l'ajouter automatiquement."
        }
    }
}

# Exécuter la fonction principale
Main
