<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences brisÃ©es dans les scripts suite Ã  la rÃ©organisation.
.DESCRIPTION
    Ce script utilise le rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences.ps1 pour mettre Ã  jour
    automatiquement les rÃ©fÃ©rences brisÃ©es dans les scripts. Il crÃ©e un journal des modifications
    effectuÃ©es et permet de valider les changements avant de les appliquer.
.PARAMETER InputPath
    Chemin du fichier de rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences.ps1.
    Par dÃ©faut: ..\..\D
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le journal des modifications.
    Par dÃ©faut: ..\..\D
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Update-BrokenReferences.ps1
    Analyse le rapport et propose des mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.
.EXAMPLE
    .\Update-BrokenReferences.ps1 -AutoApply
    Analyse le rapport et applique automatiquement les mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.

<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences brisÃ©es dans les scripts suite Ã  la rÃ©organisation.
.DESCRIPTION
    Ce script utilise le rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences.ps1 pour mettre Ã  jour
    automatiquement les rÃ©fÃ©rences brisÃ©es dans les scripts. Il crÃ©e un journal des modifications
    effectuÃ©es et permet de valider les changements avant de les appliquer.
.PARAMETER InputPath
    Chemin du fichier de rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences.ps1.
    Par dÃ©faut: ..\..\D
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le journal des modifications.
    Par dÃ©faut: ..\..\D
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Update-BrokenReferences.ps1
    Analyse le rapport et propose des mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.
.EXAMPLE
    .\Update-BrokenReferences.ps1 -AutoApply
    Analyse le rapport et applique automatiquement les mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.
#>

param (
    [string]$InputPath = "..\..\D",
    [string]$OutputPath = "..\..\D",
    [switch]$AutoApply,
    [switch]$Verbose
)

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
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal


# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = "..\..\D"
    Add-Content -Path $LogFile -Value $FormattedMessage
}

# Fonction pour trouver le nouveau chemin d'un fichier
function Find-NewPath {
    param (
        [string]$OldPath,
        [string]$ScriptPath
    )
    
    # Normaliser le chemin
    $OldPath = $OldPath.Replace('/', '\')
    
    # Extraire le nom du fichier
    $FileName = Split-Path -Path $OldPath -Leaf
    
    # Rechercher le fichier dans la nouvelle structure
    $NewPaths = Get-ChildItem -Path "scripts" -Filter $FileName -Recurse -File | Select-Object -ExpandProperty FullName
    
    if ($NewPaths.Count -eq 0) {
        return $null
    }
    
    if ($NewPaths.Count -eq 1) {
        return $NewPaths[0]
    }
    
    # Si plusieurs fichiers correspondent, essayer de trouver le plus pertinent
    $ScriptDir = Split-Path -Path $ScriptPath -Parent
    $BestMatch = $null
    $BestScore = 0
    
    foreach ($NewPath in $NewPaths) {
        $Score = 0
        
        # VÃ©rifier si le nouveau chemin contient des Ã©lÃ©ments de l'ancien chemin
        $OldPathParts = $OldPath.Split('\')
        foreach ($Part in $OldPathParts) {
            if ($Part -and $NewPath -match [regex]::Escape($Part)) {
                $Score += 1
            }
        }
        
        # VÃ©rifier si le nouveau chemin est dans le mÃªme dossier que le script
        if ($NewPath -match [regex]::Escape($ScriptDir)) {
            $Score += 2
        }
        
        if ($Score -gt $BestScore) {
            $BestScore = $Score
            $BestMatch = $NewPath
        }
    }
    
    return $BestMatch
}

# Fonction pour convertir un chemin absolu en chemin relatif
function Convert-ToRelativePath {
    param (
        [string]$Path,
        [string]$BasePath
    )
    
    # Normaliser les chemins
    $Path = [System.IO.Path]::GetFullPath($Path)
    $BasePath = [System.IO.Path]::GetFullPath($BasePath)
    
    # Si les chemins sont sur des lecteurs diffÃ©rents, retourner le chemin absolu
    if ([System.IO.Path]::GetPathRoot($Path) -ne [System.IO.Path]::GetPathRoot($BasePath)) {
        return $Path
    }
    
    # Calculer le chemin relatif
    $Uri1 = New-Object System.Uri($Path)
    $Uri2 = New-Object System.Uri($BasePath)
    $RelativeUri = $Uri2.MakeRelativeUri($Uri1)
    $RelativePath = [System.Uri]::UnescapeDataString($RelativeUri.ToString()).Replace('/', '\')
    
    return $RelativePath
}

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences dans un fichier
function Update-References {
    param (
        [string]$FilePath,
        [array]$BrokenReferences,
        [switch]$Apply
    )
    
    $Content = Get-Content -Path $FilePath -Raw
    $Updates = @()
    $Modified = $false
    
    foreach ($Reference in $BrokenReferences) {
        $OldPath = $Reference.ReferencePath
        $NewPath = Find-NewPath -OldPath $OldPath -ScriptPath $FilePath
        
        if ($NewPath) {
            # Convertir le nouveau chemin en chemin relatif si l'ancien chemin Ã©tait relatif
            if (-not ($OldPath -match '^[A-Za-z]:\\' -or $OldPath -match '^\\\\')) {
                $ScriptDir = Split-Path -Path $FilePath -Parent
                $NewPath = Convert-ToRelativePath -Path $NewPath -BasePath $ScriptDir
            }
            
            $Update = [PSCustomObject]@{
                ScriptPath = $FilePath
                OldPath = $OldPath
                NewPath = $NewPath
                LineNumbers = $Reference.LineNumbers
                Applied = $false
            }
            
            if ($Apply) {
                # Remplacer l'ancien chemin par le nouveau
                $Content = $Content.Replace($OldPath, $NewPath)
                $Update.Applied = $true
                $Modified = $true
                
                Write-Log "  Mise Ã  jour appliquÃ©e: $OldPath -> $NewPath" -Level "SUCCESS"
            } else {
                Write-Log "  Mise Ã  jour proposÃ©e: $OldPath -> $NewPath" -Level "INFO"
            }
            
            $Updates += $Update
        } else {
            Write-Log "  Impossible de trouver un nouveau chemin pour: $OldPath" -Level "WARNING"
        }
    }
    
    # Enregistrer le fichier modifiÃ©
    if ($Modified) {
        Set-Content -Path $FilePath -Value $Content
        Write-Log "  Fichier mis Ã  jour: $FilePath" -Level "SUCCESS"
    }
    
    return $Updates
}

# Fonction principale
function Update-BrokenReferences {
    param (
        [string]$InputPath,
        [string]$OutputPath,
        [switch]$AutoApply
    )
    
    Write-Log "DÃ©marrage de la mise Ã  jour des rÃ©fÃ©rences brisÃ©es..." -Level "TITLE"
    Write-Log "Fichier d'entrÃ©e: $InputPath" -Level "INFO"
    Write-Log "Fichier de sortie: $OutputPath" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord Detect-BrokenReferences.ps1 pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
    }
    
    # Charger le rapport
    $Report = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
    $TotalReferences = $Report.BrokenReferences.Count
    Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es Ã  traiter: $TotalReferences" -Level "INFO"
    
    # Initialiser les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalReferences = $TotalReferences
        Updates = @()
    }
    
    # Regrouper les rÃ©fÃ©rences par fichier
    $ReferencesByFile = @{}
    foreach ($Reference in $Report.BrokenReferences) {
        $ScriptPath = $Reference.ScriptPath
        if (-not $ReferencesByFile.ContainsKey($ScriptPath)) {
            $ReferencesByFile[$ScriptPath] = @()
        }
        $ReferencesByFile[$ScriptPath] += $Reference
    }
    
    # Traiter chaque fichier
    $FileCounter = 0
    $TotalFiles = $ReferencesByFile.Keys.Count
    foreach ($FilePath in $ReferencesByFile.Keys) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
        Write-Log "Traitement du fichier: $FilePath" -Level "INFO"
        
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "  Le fichier n'existe pas: $FilePath" -Level "ERROR"
            continue
        }
        
        # Mettre Ã  jour les rÃ©fÃ©rences
        $Updates = Update-References -FilePath $FilePath -BrokenReferences $ReferencesByFile[$FilePath] -Apply:$AutoApply
        $Results.Updates += $Updates
    }
    
    Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Completed
    
    # Enregistrer les rÃ©sultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    $UpdateCount = ($Results.Updates | Where-Object { $_.Applied } | Measure-Object).Count
    $TotalUpdates = $Results.Updates.Count
    Write-Log "Mise Ã  jour terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de rÃ©fÃ©rences traitÃ©es: $TotalReferences" -Level "INFO"
    Write-Log "Nombre de mises Ã  jour proposÃ©es: $TotalUpdates" -Level "INFO"
    if ($AutoApply) {
        Write-Log "Nombre de mises Ã  jour appliquÃ©es: $UpdateCount" -Level "SUCCESS"
    } else {
        Write-Log "Pour appliquer les mises Ã  jour, exÃ©cutez la commande suivante:" -Level "WARNING"
        Write-Log ".\Update-BrokenReferences.ps1 -AutoApply" -Level "INFO"
    }
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    return $Results
}

# ExÃ©cuter la fonction principale
Update-BrokenReferences -InputPath $InputPath -OutputPath $OutputPath -AutoApply:$AutoApply


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
