<#
.SYNOPSIS
    Teste la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences.
.DESCRIPTION
    Ce script teste spÃ©cifiquement la Phase 1 du projet de rÃ©organisation des scripts,
    qui concerne la mise Ã  jour des rÃ©fÃ©rences. Il vÃ©rifie que les chemins de fichiers
    dans les scripts sont valides et qu'il n'y a pas de rÃ©fÃ©rences brisÃ©es.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par dÃ©faut: scripts\tests\references_test_report.json
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-Phase1-References.ps1
    Teste la Phase 1 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase1-References.ps1 -Path "scripts\maintenance" -Verbose
    Teste la Phase 1 sur les scripts du dossier "scripts\maintenance" avec des informations dÃ©taillÃ©es.

<#
.SYNOPSIS
    Teste la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences.
.DESCRIPTION
    Ce script teste spÃ©cifiquement la Phase 1 du projet de rÃ©organisation des scripts,
    qui concerne la mise Ã  jour des rÃ©fÃ©rences. Il vÃ©rifie que les chemins de fichiers
    dans les scripts sont valides et qu'il n'y a pas de rÃ©fÃ©rences brisÃ©es.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par dÃ©faut: scripts\tests\references_test_report.json
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-Phase1-References.ps1
    Teste la Phase 1 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase1-References.ps1 -Path "scripts\maintenance" -Verbose
    Teste la Phase 1 sur les scripts du dossier "scripts\maintenance" avec des informations dÃ©taillÃ©es.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\references_test_report.json",
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
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour trouver les rÃ©fÃ©rences de fichiers dans un script
function Find-FileReferences {
    param (
        [string]$FilePath
    )
    
    $References = @()
    
    # Lire le contenu du fichier
    $Content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if ([string]::IsNullOrEmpty($Content)) {
        return $References
    }
    
    # Extraire les rÃ©fÃ©rences de fichiers selon le type de script
    $ScriptType = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    switch ($ScriptType) {
        ".ps1" {
            # Rechercher les chemins de fichiers dans les scripts PowerShell
            $Patterns = @(
                '(?<=\s+)([A-Za-z]:\\[^"''`\s]+)',
                '(?<=\s+)([.\\][^"''`\s]+)',
                '(?<=["\''`])([A-Za-z]:\\[^"''`]+)(?=["\''`])',
                '(?<=["\''`])([.\\][^"''`]+)(?=["\''`])'
            )
            
            foreach ($Pattern in $Patterns) {
                $Matches = [regex]::Matches($Content, $Pattern)
                foreach ($Match in $Matches) {
                    $Reference = $Match.Value
                    
                    # Ignorer les rÃ©fÃ©rences qui ne sont pas des chemins de fichiers
                    if ($Reference -match '\.(ps1|py|cmd|bat|sh|txt|csv|json|xml|html|md)$') {
                        $References += $Reference
                    }
                }
            }
        }
        ".py" {
            # Rechercher les chemins de fichiers dans les scripts Python
            $Patterns = @(
                '(?<=open\(["\'])([^"'']+)(?=["\'])',
                '(?<=with\s+open\(["\'])([^"'']+)(?=["\'])',
                '(?<=Path\(["\'])([^"'']+)(?=["\'])',
                '(?<=os\.path\.join\([^)]*["\'])([^"'']+)(?=["\'])'
            )
            
            foreach ($Pattern in $Patterns) {
                $Matches = [regex]::Matches($Content, $Pattern)
                foreach ($Match in $Matches) {
                    $References += $Match.Value
                }
            }
        }
        ".cmd" {
            # Rechercher les chemins de fichiers dans les scripts Batch
            $Patterns = @(
                '(?<=call\s+)([A-Za-z]:\\[^"\s]+)',
                '(?<=call\s+)([.\\][^"\s]+)',
                '(?<=call\s+")([^"]+)(?=")'
            )
            
            foreach ($Pattern in $Patterns) {
                $Matches = [regex]::Matches($Content, $Pattern)
                foreach ($Match in $Matches) {
                    $References += $Match.Value
                }
            }
        }
        ".bat" {
            # Rechercher les chemins de fichiers dans les scripts Batch
            $Patterns = @(
                '(?<=call\s+)([A-Za-z]:\\[^"\s]+)',
                '(?<=call\s+)([.\\][^"\s]+)',
                '(?<=call\s+")([^"]+)(?=")'
            )
            
            foreach ($Pattern in $Patterns) {
                $Matches = [regex]::Matches($Content, $Pattern)
                foreach ($Match in $Matches) {
                    $References += $Match.Value
                }
            }
        }
        ".sh" {
            # Rechercher les chemins de fichiers dans les scripts Shell
            $Patterns = @(
                '(?<=source\s+)([A-Za-z]:\\[^"\s]+)',
                '(?<=source\s+)([.\\][^"\s]+)',
                '(?<=source\s+")([^"]+)(?=")',
                '(?<=\.\s+)([A-Za-z]:\\[^"\s]+)',
                '(?<=\.\s+)([.\\][^"\s]+)',
                '(?<=\.\s+")([^"]+)(?=")'
            )
            
            foreach ($Pattern in $Patterns) {
                $Matches = [regex]::Matches($Content, $Pattern)
                foreach ($Match in $Matches) {
                    $References += $Match.Value
                }
            }
        }
    }
    
    return $References
}

# Fonction pour vÃ©rifier si une rÃ©fÃ©rence est valide
function Test-Reference {
    param (
        [string]$Reference,
        [string]$BasePath
    )
    
    # Ignorer les rÃ©fÃ©rences vides
    if ([string]::IsNullOrEmpty($Reference)) {
        return $true
    }
    
    # Convertir les chemins relatifs en chemins absolus
    $FullPath = $Reference
    if ($Reference -match '^\.') {
        $FullPath = Join-Path -Path $BasePath -ChildPath $Reference
    }
    
    # VÃ©rifier si le fichier existe
    return Test-Path -Path $FullPath -ErrorAction SilentlyContinue
}

# Fonction principale
function Test-References {
    param (
        [string]$Path,
        [string]$OutputPath,
        [switch]$Verbose
    )
    
    Write-Log "=== Test de la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences ===" -Level "TITLE"
    Write-Log "Chemin des scripts Ã  tester: $Path" -Level "INFO"
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "INFO"
    }
    
    # RÃ©cupÃ©rer tous les fichiers de script
    $ScriptExtensions = @("*.ps1", "*.py", "*.cmd", "*.bat", "*.sh")
    $AllFiles = @()
    foreach ($Extension in $ScriptExtensions) {
        $AllFiles += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
    }
    
    Write-Log "Nombre de scripts trouvÃ©s: $($AllFiles.Count)" -Level "INFO"
    
    # Initialiser les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $AllFiles.Count
        ScriptsWithReferences = 0
        TotalReferences = 0
        BrokenReferences = @()
        BrokenReferencesCount = 0
    }
    
    # Analyser chaque fichier
    foreach ($File in $AllFiles) {
        if ($Verbose) {
            Write-Log "Analyse du fichier: $($File.FullName)" -Level "INFO"
        }
        
        # Trouver les rÃ©fÃ©rences de fichiers
        $References = Find-FileReferences -FilePath $File.FullName
        
        if ($References.Count -gt 0) {
            $Results.ScriptsWithReferences++
            $Results.TotalReferences += $References.Count
            
            if ($Verbose) {
                Write-Log "  RÃ©fÃ©rences trouvÃ©es: $($References.Count)" -Level "INFO"
            }
            
            # VÃ©rifier chaque rÃ©fÃ©rence
            foreach ($Reference in $References) {
                $IsValid = Test-Reference -Reference $Reference -BasePath $File.DirectoryName
                
                if (-not $IsValid) {
                    $BrokenReference = [PSCustomObject]@{
                        ScriptPath = $File.FullName
                        Reference = $Reference
                    }
                    
                    $Results.BrokenReferences += $BrokenReference
                    $Results.BrokenReferencesCount++
                    
                    if ($Verbose) {
                        Write-Log "    RÃ©fÃ©rence brisÃ©e: $Reference" -Level "WARNING"
                    }
                }
            }
        }
    }
    
    # Enregistrer les rÃ©sultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    Write-Log "Analyse terminÃ©e" -Level "INFO"
    Write-Log "Nombre total de scripts analysÃ©s: $($Results.TotalScripts)" -Level "INFO"
    Write-Log "Nombre de scripts avec rÃ©fÃ©rences: $($Results.ScriptsWithReferences)" -Level "INFO"
    Write-Log "Nombre total de rÃ©fÃ©rences: $($Results.TotalReferences)" -Level "INFO"
    Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es: $($Results.BrokenReferencesCount)" -Level $(if ($Results.BrokenReferencesCount -gt 0) { "WARNING" } else { "SUCCESS" })
    
    if ($Results.BrokenReferencesCount -gt 0) {
        Write-Log "Des rÃ©fÃ©rences brisÃ©es ont Ã©tÃ© dÃ©tectÃ©es. Consultez le rapport pour plus de dÃ©tails: $OutputPath" -Level "WARNING"
        Write-Log "La Phase 1 n'a pas complÃ¨tement rÃ©ussi" -Level "WARNING"
        return $false
    } else {
        Write-Log "Aucune rÃ©fÃ©rence brisÃ©e dÃ©tectÃ©e" -Level "SUCCESS"
        Write-Log "La Phase 1 a rÃ©ussi" -Level "SUCCESS"
        return $true
    }
}

# ExÃ©cuter le test
$Success = Test-References -Path $Path -OutputPath $OutputPath -Verbose:$Verbose

# Retourner le rÃ©sultat
return $Success

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
