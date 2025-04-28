<#
.SYNOPSIS
    DÃ©tecte les rÃ©fÃ©rences brisÃ©es dans les scripts suite Ã  la rÃ©organisation.
.DESCRIPTION
    Ce script analyse tous les scripts du projet pour identifier les chemins de fichiers
    qui ne correspondent plus Ã  la nouvelle structure de dossiers. Il gÃ©nÃ¨re un rapport
    des rÃ©fÃ©rences Ã  mettre Ã  jour.
.PARAMETER ScriptsPath
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par dÃ©faut: ..\..\D
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Detect-BrokenReferences-Fixed.ps1
    Analyse tous les scripts dans le dossier scripts et gÃ©nÃ¨re un rapport.
.EXAMPLE
    .\Detect-BrokenReferences-Fixed.ps1 -ScriptsPath "D:\scripts" -OutputPath "D:\rapport.json"
    Analyse tous les scripts dans le dossier D:\scripts et gÃ©nÃ¨re un rapport dans D:\rapport.json.
#>

param (
    [string]$ScriptsPath = "scripts",
    [string]$OutputPath = "..\..\D",
    [switch]$Verbose
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

# Fonction pour obtenir tous les fichiers de script
function Get-ScriptFiles {
    param (
        [string]$Path
    )

    $ScriptExtensions = @("*.ps1", "*.psm1", "*.psd1", "*.py", "*.cmd", "*.bat", "*.sh")
    $Files = @()

    foreach ($Extension in $ScriptExtensions) {
        $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
    }

    return $Files
}

# Fonction pour obtenir les chemins de fichiers d'un script
function Get-FilePaths {
    param (
        [string]$FilePath
    )

    $Content = Get-Content -Path $FilePath -Raw
    $Paths = @()

    # ModÃ¨les de recherche pour les chemins de fichiers
    $Patterns = @(
        # Chemins entre guillemets
        '["'']((?:\.{1,2}\\|[a-zA-Z]:\\|\\\\|scripts\\|manager\\|maintenance\\|workflow\\|api\\|core\\|utils\\|docs\\|setup\\|journal\\|email\\|testing\\|mcp\\|python\\)[^"'']*\.[a-zA-Z0-9]+)[''"]',
        # Chemins dans Join-Path
        'Join-Path\s+(?:-Path\s+)?["'']([^"'']+)["'']\s+(?:-ChildPath\s+)?["'']([^"'']+)[''"]',
        # Chemins dans Get-ChildItem, Get-Content, etc.
        '(?:Get-ChildItem|Get-Content|Set-Content|Test-Path|Remove-Item|Copy-Item|Move-Item|New-Item)\s+(?:-Path\s+)?["'']([^"'']+)[''"]',
        # Chemins dans Import-Module, Import-PSModule, etc.
        '(?:Import-Module|Import-PSModule|Import-Script)\s+(?:-Path\s+)?["'']([^"'']+)[''"]',
        # Chemins dans Invoke-Expression, Invoke-Command, etc.
        '(?:Invoke-Expression|Invoke-Command|Invoke-Script)\s+(?:-Command\s+)?["''](?:[^"'']*\s+)([^"'']+\.(?:ps1|py|cmd|bat|sh))[''"]',
        # Chemins dans les imports Python
        'import\s+([a-zA-Z0-9_.]+)',
        'from\s+([a-zA-Z0-9_.]+)\s+import',
        # Chemins dans les includes/requires
        '#include\s+["'']([^"'']+)[''"]',
        '#require\s+["'']([^"'']+)[''"]',
        # Chemins dans les appels de scripts
        '&\s+["'']([^"'']+)[''"]',
        '\.\s+["'']([^"'']+)[''"]'
    )

    foreach ($Pattern in $Patterns) {
        $RegexMatches = [regex]::Matches($Content, $Pattern)
        foreach ($Match in $RegexMatches) {
            if ($Match.Groups.Count -gt 1) {
                for ($i = 1; $i -lt $Match.Groups.Count; $i++) {
                    $Path = $Match.Groups[$i].Value
                    if ($Path -and $Path -ne "") {
                        $Paths += $Path
                    }
                }
            }
        }
    }

    # Filtrer les chemins uniques
    $Paths = $Paths | Select-Object -Unique

    return $Paths
}

# Fonction pour vÃ©rifier si un chemin existe
function Test-PathExists {
    param (
        [string]$Path,
        [string]$BasePath,
        [string]$ScriptPath
    )

    # VÃ©rifier si le chemin est vide
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    # Normaliser le chemin
    $Path = $Path.Replace('/', '\')

    # Chemins absolus
    if ($Path -match '^[A-Za-z]:\\' -or $Path -match '^\\\\') {
        return (Test-Path -Path $Path -ErrorAction SilentlyContinue)
    }

    # Chemins relatifs au script
    $ScriptDir = Split-Path -Path $ScriptPath -Parent
    $FullPath = Join-Path -Path $ScriptDir -ChildPath $Path
    if (Test-Path -Path $FullPath -ErrorAction SilentlyContinue) {
        return $true
    }

    # Chemins relatifs Ã  la racine du projet
    $FullPath = Join-Path -Path $BasePath -ChildPath $Path
    if (Test-Path -Path $FullPath -ErrorAction SilentlyContinue) {
        return $true
    }

    # Chemins relatifs avec ..
    if ($Path -match '^\.\.' -or $Path -match '^\./') {
        try {
            $FullPath = [System.IO.Path]::GetFullPath((Join-Path -Path $ScriptDir -ChildPath $Path))
            if (Test-Path -Path $FullPath -ErrorAction SilentlyContinue) {
                return $true
            }
        } catch {
            # Ignorer les erreurs de chemin invalide
            return $false
        }
    }

    return $false
}

# Fonction principale
function Find-BrokenReferences {
    param (
        [string]$ScriptsPath,
        [string]$OutputPath
    )

    Write-Log "DÃ©marrage de la dÃ©tection des rÃ©fÃ©rences brisÃ©es..." -Level "TITLE"
    Write-Log "Dossier des scripts: $ScriptsPath" -Level "INFO"
    Write-Log "Fichier de sortie: $OutputPath" -Level "INFO"

    # VÃ©rifier si le dossier des scripts existe
    if (-not (Test-Path -Path $ScriptsPath)) {
        Write-Log "Le dossier des scripts n'existe pas: $ScriptsPath" -Level "ERROR"
        return
    }

    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
    }

    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $ScriptsPath
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers Ã  analyser: $TotalFiles" -Level "INFO"

    # Initialiser les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $TotalFiles
        BrokenReferences = @()
    }

    # Analyser chaque fichier
    $FileCounter = 0
    foreach ($File in $ScriptFiles) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Analyse des rÃ©fÃ©rences" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress

        if ($Verbose) {
            Write-Log "Analyse du fichier: $($File.FullName)" -Level "INFO"
        }

        # Obtenir les chemins de fichiers
        $Paths = Get-FilePaths -FilePath $File.FullName

        # VÃ©rifier chaque chemin
        foreach ($Path in $Paths) {
            if (-not (Test-PathExists -Path $Path -BasePath (Split-Path -Path $ScriptsPath -Parent) -ScriptPath $File.FullName)) {
                $BrokenReference = [PSCustomObject]@{
                    ScriptPath = $File.FullName
                    ReferencePath = $Path
                    LineNumbers = @()
                }

                # Trouver les numÃ©ros de ligne oÃ¹ la rÃ©fÃ©rence apparaÃ®t
                $Content = Get-Content -Path $File.FullName
                for ($i = 0; $i -lt $Content.Length; $i++) {
                    if ($Content[$i] -match [regex]::Escape($Path)) {
                        $BrokenReference.LineNumbers += ($i + 1)
                    }
                }

                $Results.BrokenReferences += $BrokenReference

                if ($Verbose) {
                    Write-Log "  RÃ©fÃ©rence brisÃ©e trouvÃ©e: $Path" -Level "WARNING"
                }
            }
        }
    }

    Write-Progress -Activity "Analyse des rÃ©fÃ©rences" -Completed

    # Enregistrer les rÃ©sultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath

    # Afficher un rÃ©sumÃ©
    $BrokenCount = $Results.BrokenReferences.Count
    Write-Log "Analyse terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysÃ©s: $TotalFiles" -Level "INFO"
    Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es trouvÃ©es: $BrokenCount" -Level "WARNING"
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"

    return $Results
}

# ExÃ©cuter la fonction principale
Find-BrokenReferences -ScriptsPath $ScriptsPath -OutputPath $OutputPath

