# Script pour centraliser l'accès au fichier roadmap
# Ce script retourne le chemin absolu du fichier roadmap principal

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "logs"
        $logPath = Join-Path -Path $logDir -ChildPath "roadmap_access.log"
        
        # Créer le répertoire de logs si nécessaire
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}

try {
    # Définir le chemin absolu du fichier roadmap principal
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $roadmapPath = "Roadmap\roadmap_perso.md"""
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $roadmapPath -PathType Leaf)) {
        Write-Log -Level ERROR -Message "Le fichier roadmap principal n'existe pas: $roadmapPath"
        throw "Le fichier roadmap principal n'existe pas: $roadmapPath"
    }
    
    # Retourner le chemin absolu
    return $roadmapPath
}
catch {
    Write-Log -Level ERROR -Message "Une erreur s'est produite lors de l'accès au fichier roadmap: $_"
    throw $_
}
