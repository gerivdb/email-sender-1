<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences brisÃ©es dans les scripts suite Ã  la rÃ©organisation.
.DESCRIPTION
    Ce script utilise le rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences-Fixed.ps1 pour mettre Ã  jour
    automatiquement les rÃ©fÃ©rences brisÃ©es dans les scripts. Il crÃ©e un journal des modifications
    effectuÃ©es et permet de valider les changements avant de les appliquer.
.PARAMETER InputPath
    Chemin du fichier de rapport gÃ©nÃ©rÃ© par Detect-BrokenReferences-Fixed.ps1.
    Par dÃ©faut: ..\..\D
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le journal des modifications.
    Par dÃ©faut: ..\..\D
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Update-BrokenReferences-Fixed.ps1
    Analyse le rapport et propose des mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.
.EXAMPLE
    .\Update-BrokenReferences-Fixed.ps1 -AutoApply
    Analyse le rapport et applique automatiquement les mises Ã  jour pour les rÃ©fÃ©rences brisÃ©es.
#>

param (
    [string]$InputPath = "..\..\D",
    [string]$OutputPath = "..\..\D",
    [switch]$AutoApply,
    [switch]$ShowDetails
)

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
    
    # VÃ©rifier si le chemin est vide
    if ([string]::IsNullOrWhiteSpace($OldPath)) {
        return $null
    }
    
    # Normaliser le chemin
    $OldPath = $OldPath.Replace('/', '\')
    
    # Extraire le nom du fichier
    $FileName = Split-Path -Path $OldPath -Leaf
    
    # Rechercher le fichier dans la nouvelle structure
    $NewPaths = Get-ChildItem -Path "scripts" -Filter $FileName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    
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
    
    # VÃ©rifier si les chemins sont vides
    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($BasePath)) {
        return $Path
    }
    
    try {
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
    } catch {
        # En cas d'erreur, retourner le chemin original
        Write-Log "Erreur lors de la conversion du chemin: $_" -Level "WARNING"
        return $Path
    }
}

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences dans un fichier
function Update-References {
    param (
        [string]$FilePath,
        [array]$BrokenReferences,
        [switch]$Apply
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -ErrorAction SilentlyContinue)) {
        Write-Log "  Le fichier n'existe pas: $FilePath" -Level "ERROR"
        return @()
    }
    
    $Content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $Content) {
        Write-Log "  Impossible de lire le contenu du fichier: $FilePath" -Level "ERROR"
        return @()
    }
    
    $Updates = @()
    $Modified = $false
    
    foreach ($Reference in $BrokenReferences) {
        $OldPath = $Reference.ReferencePath
        
        # VÃ©rifier si le chemin est vide
        if ([string]::IsNullOrWhiteSpace($OldPath)) {
            continue
        }
        
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
        try {
            Set-Content -Path $FilePath -Value $Content -ErrorAction Stop
            Write-Log "  Fichier mis Ã  jour: $FilePath" -Level "SUCCESS"
        } catch {
            Write-Log "  Erreur lors de l'enregistrement du fichier: $FilePath - $_" -Level "ERROR"
        }
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
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord Detect-BrokenReferences-Fixed.ps1 pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir -ErrorAction SilentlyContinue)) {
        try {
            New-Item -ItemType Directory -Path $OutputDir -Force -ErrorAction Stop | Out-Null
            Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
        } catch {
            Write-Log "Erreur lors de la crÃ©ation du dossier de sortie: $_" -Level "ERROR"
            return $false
        }
    }
    
    # Charger le rapport
    try {
        $Report = Get-Content -Path $InputPath -Raw -ErrorAction Stop | ConvertFrom-Json
        $TotalReferences = $Report.BrokenReferences.Count
        Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es Ã  traiter: $TotalReferences" -Level "INFO"
    } catch {
        Write-Log "Erreur lors du chargement du rapport: $_" -Level "ERROR"
        return $false
    }
    
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
        
        # Mettre Ã  jour les rÃ©fÃ©rences
        $Updates = Update-References -FilePath $FilePath -BrokenReferences $ReferencesByFile[$FilePath] -Apply:$AutoApply
        $Results.Updates += $Updates
    }
    
    Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Completed
    
    # Enregistrer les rÃ©sultats
    try {
        $Results | ConvertTo-Json -Depth 10 -ErrorAction Stop | Set-Content -Path $OutputPath -ErrorAction Stop
    } catch {
        Write-Log "Erreur lors de l'enregistrement des rÃ©sultats: $_" -Level "ERROR"
        return $false
    }
    
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
        Write-Log ".\Update-BrokenReferences-Fixed.ps1 -AutoApply" -Level "INFO"
    }
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    return $true
}

# ExÃ©cuter la fonction principale
Update-BrokenReferences -InputPath $InputPath -OutputPath $OutputPath -AutoApply:$AutoApply

