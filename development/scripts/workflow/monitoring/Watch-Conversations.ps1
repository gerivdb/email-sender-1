# Watch-Conversations.ps1
# Script pour surveiller un dossier de conversations et traiter automatiquement les nouveaux fichiers

param (
    [Parameter(Mandatory = $false)]
    [string]$ConversationsFolder = ".\conversations",
    
    [Parameter(Mandatory = $false)]
    [switch]$AddToRoadmap,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 60
)

# VÃ©rifier que le dossier de conversations existe, sinon le crÃ©er
if (-not (Test-Path -Path $ConversationsFolder)) {
    New-Item -Path $ConversationsFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de conversations crÃ©Ã© : $ConversationsFolder"
}

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$processConversationPath = Join-Path -Path $scriptPath -ChildPath "Process-Conversation.ps1"
$processedFilesPath = Join-Path -Path $scriptPath -ChildPath "processed-files.txt"

# VÃ©rifier que le script de traitement des conversations existe
if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $processConversationPath"
    exit 1
}

# Fonction pour obtenir la liste des fichiers dÃ©jÃ  traitÃ©s
function Get-ProcessedFiles {
    if (-not (Test-Path -Path $processedFilesPath)) {
        return @()
    }
    
    return Get-Content -Path $processedFilesPath
}

# Fonction pour marquer un fichier comme traitÃ©
function Set-FileAsProcessed {
    param (
        [string]$FilePath
    )
    
    $processedFiles = Get-ProcessedFiles
    $processedFiles += $FilePath
    $processedFiles | Set-Content -Path $processedFilesPath
}

# Fonction pour traiter un fichier de conversation
function Invoke-ConversationFile {
    param (
        [string]$FilePath
    )
    
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$processConversationPath`" -ConversationFile `"$FilePath`" $addToRoadmapParam $verboseParam"
    
    if ($Verbose) {
        Write-Host "ExÃ©cution de la commande : $command"
    }
    
    try {
        Invoke-Expression $command
        Set-FileAsProcessed -FilePath $FilePath
        return $true
    }
    catch {
        Write-Error "Erreur lors du traitement du fichier de conversation : $_"
        return $false
    }
}

# Fonction principale pour surveiller le dossier
function Watch-ConversationsFolder {
    Write-Host "Surveillance du dossier de conversations : $ConversationsFolder"
    Write-Host "Intervalle de vÃ©rification : $IntervalSeconds secondes"
    Write-Host "Ajout automatique Ã  la roadmap : $AddToRoadmap"
    Write-Host "Mode verbeux : $Verbose"
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arrÃªter la surveillance."
    Write-Host ""
    
    $processedFiles = Get-ProcessedFiles
    
    while ($true) {
        # Obtenir la liste des fichiers de conversation
        $conversationFiles = Get-ChildItem -Path $ConversationsFolder -Filter "*.txt" | Select-Object -ExpandProperty FullName
        
        # Traiter les nouveaux fichiers
        foreach ($file in $conversationFiles) {
            if ($processedFiles -notcontains $file) {
                Write-Host "Nouveau fichier dÃ©tectÃ© : $file"
                $success = Invoke-ConversationFile -FilePath $file
                
                if ($success) {
                    Write-Host "Fichier traitÃ© avec succÃ¨s : $file" -ForegroundColor Green
                }
                else {
                    Write-Host "Ã‰chec du traitement du fichier : $file" -ForegroundColor Red
                }
                
                Write-Host ""
            }
        }
        
        # Mettre Ã  jour la liste des fichiers traitÃ©s
        $processedFiles = Get-ProcessedFiles
        
        # Attendre avant la prochaine vÃ©rification
        Start-Sleep -Seconds $IntervalSeconds
    }
}

# DÃ©marrer la surveillance
Watch-ConversationsFolder


