<#
.SYNOPSIS
    Teste la Phase 1 : Mise à jour des références.
.DESCRIPTION
    Ce script teste spécifiquement la Phase 1 du projet de réorganisation des scripts,
    qui concerne la mise à jour des références. Il vérifie que les chemins de fichiers
    dans les scripts sont valides et qu'il n'y a pas de références brisées.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par défaut: scripts\tests\references_test_report.json
.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Test-Phase1-References.ps1
    Teste la Phase 1 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase1-References.ps1 -Path "scripts\maintenance" -Verbose
    Teste la Phase 1 sur les scripts du dossier "scripts\maintenance" avec des informations détaillées.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\references_test_report.json",
    [switch]$Verbose
)

# Fonction pour écrire des messages de log
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
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour trouver les références de fichiers dans un script
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
    
    # Extraire les références de fichiers selon le type de script
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
                    
                    # Ignorer les références qui ne sont pas des chemins de fichiers
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

# Fonction pour vérifier si une référence est valide
function Test-Reference {
    param (
        [string]$Reference,
        [string]$BasePath
    )
    
    # Ignorer les références vides
    if ([string]::IsNullOrEmpty($Reference)) {
        return $true
    }
    
    # Convertir les chemins relatifs en chemins absolus
    $FullPath = $Reference
    if ($Reference -match '^\.') {
        $FullPath = Join-Path -Path $BasePath -ChildPath $Reference
    }
    
    # Vérifier si le fichier existe
    return Test-Path -Path $FullPath -ErrorAction SilentlyContinue
}

# Fonction principale
function Test-References {
    param (
        [string]$Path,
        [string]$OutputPath,
        [switch]$Verbose
    )
    
    Write-Log "=== Test de la Phase 1 : Mise à jour des références ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "INFO"
    }
    
    # Récupérer tous les fichiers de script
    $ScriptExtensions = @("*.ps1", "*.py", "*.cmd", "*.bat", "*.sh")
    $AllFiles = @()
    foreach ($Extension in $ScriptExtensions) {
        $AllFiles += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
    }
    
    Write-Log "Nombre de scripts trouvés: $($AllFiles.Count)" -Level "INFO"
    
    # Initialiser les résultats
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
        
        # Trouver les références de fichiers
        $References = Find-FileReferences -FilePath $File.FullName
        
        if ($References.Count -gt 0) {
            $Results.ScriptsWithReferences++
            $Results.TotalReferences += $References.Count
            
            if ($Verbose) {
                Write-Log "  Références trouvées: $($References.Count)" -Level "INFO"
            }
            
            # Vérifier chaque référence
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
                        Write-Log "    Référence brisée: $Reference" -Level "WARNING"
                    }
                }
            }
        }
    }
    
    # Enregistrer les résultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    Write-Log "Analyse terminée" -Level "INFO"
    Write-Log "Nombre total de scripts analysés: $($Results.TotalScripts)" -Level "INFO"
    Write-Log "Nombre de scripts avec références: $($Results.ScriptsWithReferences)" -Level "INFO"
    Write-Log "Nombre total de références: $($Results.TotalReferences)" -Level "INFO"
    Write-Log "Nombre de références brisées: $($Results.BrokenReferencesCount)" -Level $(if ($Results.BrokenReferencesCount -gt 0) { "WARNING" } else { "SUCCESS" })
    
    if ($Results.BrokenReferencesCount -gt 0) {
        Write-Log "Des références brisées ont été détectées. Consultez le rapport pour plus de détails: $OutputPath" -Level "WARNING"
        Write-Log "La Phase 1 n'a pas complètement réussi" -Level "WARNING"
        return $false
    } else {
        Write-Log "Aucune référence brisée détectée" -Level "SUCCESS"
        Write-Log "La Phase 1 a réussi" -Level "SUCCESS"
        return $true
    }
}

# Exécuter le test
$Success = Test-References -Path $Path -OutputPath $OutputPath -Verbose:$Verbose

# Retourner le résultat
return $Success
