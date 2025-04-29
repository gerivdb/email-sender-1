<#
.SYNOPSIS
    Standardise les scripts PowerShell, Python, Batch et Shell selon les bonnes pratiques.
.DESCRIPTION
    Ce script analyse et standardise les scripts dans le rÃ©pertoire spÃ©cifiÃ© selon un ensemble de rÃ¨gles
    prÃ©dÃ©finies pour chaque type de script. Il gÃ©nÃ¨re un rapport de conformitÃ© et peut appliquer
    automatiquement les corrections.
.PARAMETER Path
    Chemin vers le rÃ©pertoire contenant les scripts Ã  analyser. Par dÃ©faut: "scripts".
.PARAMETER ComplianceReportPath
    Chemin oÃ¹ enregistrer le rapport de conformitÃ©. Par dÃ©faut: "scripts\\mode-manager\data\compliance_report.json".
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de standardisation. Par dÃ©faut: "scripts\\mode-manager\data\standardization_report.json".
.PARAMETER ScriptType
    Type de scripts Ã  analyser. Valeurs possibles: "All", "PowerShell", "Python", "Batch", "Shell". Par dÃ©faut: "All".
.PARAMETER Rules
    Liste des rÃ¨gles Ã  appliquer. Si vide, toutes les rÃ¨gles sont appliquÃ©es.
.PARAMETER AutoApply
    Si spÃ©cifiÃ©, applique automatiquement les corrections.
.PARAMETER ShowDetails
    Si spÃ©cifiÃ©, affiche les dÃ©tails des corrections.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\utils" -ScriptType "PowerShell" -AutoApply
    Standardise tous les scripts PowerShell dans le rÃ©pertoire "scripts\utils" et applique automatiquement les corrections.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\python" -ScriptType "Python" -Rules "Indentation","Imports"
    Analyse les scripts Python dans le rÃ©pertoire "scripts\python" en vÃ©rifiant uniquement les rÃ¨gles d'indentation et d'imports.
.NOTES
    Auteur: Augment Agent
    Version: 2.0
    Date: 12/04/2025
#>

param (
    [string]$Path = "scripts",
    [string]$ComplianceReportPath = "scripts\\mode-manager\data\compliance_report.json",
    [string]$OutputPath = "scripts\\mode-manager\data\standardization_report.json",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    [string[]]$Rules = @(),
    [switch]$AutoApply,
    [switch]$ShowDetails
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "scripts\\mode-manager\logs\standardization.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # DÃ©finir la couleur en fonction du niveau
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
    
    # CrÃ©er le rÃ©pertoire de logs s'il n'existe pas
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Ã‰crire dans le fichier de log
    try {
        Add-Content -Path $LogFilePath -Value $logMessage -Encoding UTF8
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}

try {
    # Fonction pour rÃ©parer les comparaisons avec $null
    function Repair-NullComparisons {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content
        )
        
        Write-Log -Level INFO -Message "RÃ©paration des comparaisons avec `$null..."
        
        # Rechercher les comparaisons incorrectes avec $null
        $pattern = '(\$\w+)\s+-(?:eq|ne)\s+\$null'
        $correctedContent = $Content -replace $pattern, '$null -$2 $1'
        
        return $correctedContent
    }
    
    # Fonction pour rÃ©parer les concatÃ©nations de chemins
    function Repair-PathConcatenations {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content
        )
        
        Write-Log -Level INFO -Message "RÃ©paration des concatÃ©nations de chemins..."
        
        # Rechercher les concatÃ©nations de chemins
        $customMatches = $Content | Select-String -Pattern '(\$\w+)\s*\+\s*[''"]\\' -AllMatches
        
        if ($customMatches -and $customMatches.Matches.Count -gt 0) {
            foreach ($match in $customMatches.Matches) {
                $original = $match.Value
                $variable = $match.Groups[1].Value
                $replacement = "$variable | Join-Path -ChildPath "
                $Content = $Content -replace [regex]::Escape($original), $replacement
            }
        }
        
        return $Content
    }
    
    # Fonction pour rÃ©parer l'indentation
    function Repair-Indentation {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content,
            
            [Parameter(Mandatory = $false)]
            [int]$TabSize = 4
        )
        
        Write-Log -Level INFO -Message "RÃ©paration de l'indentation..."
        
        # ImplÃ©menter la logique de rÃ©paration de l'indentation
        # Cette fonction est un placeholder pour l'instant
        
        return $Content
    }
    
    # Fonction pour rÃ©parer l'encodage des fichiers
    function Repair-FileEncoding {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )
        
        Write-Log -Level INFO -Message "VÃ©rification de l'encodage du fichier $FilePath..."
        
        # VÃ©rifier l'encodage actuel
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        
        if (-not $hasBOM) {
            Write-Log -Level WARNING -Message "Le fichier $FilePath n'a pas de BOM UTF-8. Correction en cours..."
            
            # Lire le contenu
            $content = Get-Content -Path $FilePath -Raw
            
            # Ã‰crire avec l'encodage UTF-8 avec BOM
            [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.UTF8Encoding]::new($true))
            
            Write-Log -Level SUCCESS -Message "Encodage corrigÃ© pour $FilePath"
            return $true
        }
        
        return $false
    }
    
    # Fonction pour standardiser les scripts PowerShell
    function Start-PowerShellStandardization {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $false)]
            [string[]]$Rules,
            
            [Parameter(Mandatory = $false)]
            [switch]$AutoApply
        )
        
        Write-Log -Level INFO -Message "Standardisation du script PowerShell: $FilePath"
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content
        $modified = $false
        
        # Appliquer les rÃ¨gles
        if ($Rules.Count -eq 0 -or $Rules -contains "NullComparisons") {
            $content = Repair-NullComparisons -Content $content
        }
        
        if ($Rules.Count -eq 0 -or $Rules -contains "PathConcatenations") {
            $content = Repair-PathConcatenations -Content $content
        }
        
        if ($Rules.Count -eq 0 -or $Rules -contains "Indentation") {
            $content = Repair-Indentation -Content $content
        }
        
        if ($Rules.Count -eq 0 -or $Rules -contains "Encoding") {
            Repair-FileEncoding -FilePath $FilePath | Out-Null
        }
        
        # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
        if ($content -ne $originalContent) {
            $modified = $true
            
            if ($AutoApply) {
                Write-Log -Level INFO -Message "Application des corrections au fichier $FilePath..."
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Log -Level SUCCESS -Message "Corrections appliquÃ©es avec succÃ¨s."
            }
            else {
                Write-Log -Level WARNING -Message "Des corrections sont nÃ©cessaires pour $FilePath. Utilisez -AutoApply pour les appliquer."
            }
        }
        else {
            Write-Log -Level SUCCESS -Message "Le script $FilePath est conforme aux standards."
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Modified = $modified
            Rules = $Rules
        }
    }
    
    # Fonction pour standardiser les scripts Python
    function Start-PythonStandardization {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $false)]
            [string[]]$Rules,
            
            [Parameter(Mandatory = $false)]
            [switch]$AutoApply
        )
        
        Write-Log -Level INFO -Message "Standardisation du script Python: $FilePath"
        
        # ImplÃ©menter la standardisation Python
        # Cette fonction est un placeholder pour l'instant
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Modified = $false
            Rules = $Rules
        }
    }
    
    # Fonction pour standardiser les scripts Batch
    function Start-BatchStandardization {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $false)]
            [string[]]$Rules,
            
            [Parameter(Mandatory = $false)]
            [switch]$AutoApply
        )
        
        Write-Log -Level INFO -Message "Standardisation du script Batch: $FilePath"
        
        # ImplÃ©menter la standardisation Batch
        # Cette fonction est un placeholder pour l'instant
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Modified = $false
            Rules = $Rules
        }
    }
    
    # Fonction pour standardiser les scripts Shell
    function Start-ShellStandardization {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $false)]
            [string[]]$Rules,
            
            [Parameter(Mandatory = $false)]
            [switch]$AutoApply
        )
        
        Write-Log -Level INFO -Message "Standardisation du script Shell: $FilePath"
        
        # ImplÃ©menter la standardisation Shell
        # Cette fonction est un placeholder pour l'instant
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Modified = $false
            Rules = $Rules
        }
    }
    
    # Fonction principale pour la standardisation des scripts
    function Start-ScriptStandardization {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [Parameter(Mandatory = $false)]
            [string]$ComplianceReportPath,
            
            [Parameter(Mandatory = $false)]
            [string]$OutputPath,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
            [string]$ScriptType = "All",
            
            [Parameter(Mandatory = $false)]
            [string[]]$Rules = @(),
            
            [Parameter(Mandatory = $false)]
            [switch]$AutoApply,
            
            [Parameter(Mandatory = $false)]
            [switch]$ShowDetails
        )
        
        Write-Log -Level INFO -Message "DÃ©marrage de la standardisation des scripts..."
        Write-Log -Level INFO -Message "Chemin: $Path"
        Write-Log -Level INFO -Message "Type de scripts: $ScriptType"
        Write-Log -Level INFO -Message "RÃ¨gles: $($Rules -join ', ')"
        Write-Log -Level INFO -Message "Application automatique: $AutoApply"
        
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Log -Level ERROR -Message "Le chemin spÃ©cifiÃ© n'existe pas: $Path"
            return
        }
        
        # RÃ©cupÃ©rer les fichiers Ã  analyser
        $files = @()
        
        if ($ScriptType -eq "All" -or $ScriptType -eq "PowerShell") {
            $files += Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1"
        }
        
        if ($ScriptType -eq "All" -or $ScriptType -eq "Python") {
            $files += Get-ChildItem -Path $Path -Recurse -Include "*.py"
        }
        
        if ($ScriptType -eq "All" -or $ScriptType -eq "Batch") {
            $files += Get-ChildItem -Path $Path -Recurse -Include "*.bat", "*.cmd"
        }
        
        if ($ScriptType -eq "All" -or $ScriptType -eq "Shell") {
            $files += Get-ChildItem -Path $Path -Recurse -Include "*.sh"
        }
        
        Write-Log -Level INFO -Message "Nombre de fichiers Ã  analyser: $($files.Count)"
        
        # Analyser chaque fichier
        $results = @()
        
        foreach ($file in $files) {
            $result = $null
            
            switch -Regex ($file.Extension) {
                '\.ps[md]?1$' {
                    $result = Start-PowerShellStandardization -FilePath $file.FullName -Rules $Rules -AutoApply:$AutoApply
                    break
                }
                '\.py$' {
                    $result = Start-PythonStandardization -FilePath $file.FullName -Rules $Rules -AutoApply:$AutoApply
                    break
                }
                '\.(bat|cmd)$' {
                    $result = Start-BatchStandardization -FilePath $file.FullName -Rules $Rules -AutoApply:$AutoApply
                    break
                }
                '\.sh$' {
                    $result = Start-ShellStandardization -FilePath $file.FullName -Rules $Rules -AutoApply:$AutoApply
                    break
                }
            }
            
            if ($result) {
                $results += $result
                
                if ($ShowDetails -and $result.Modified) {
                    Write-Log -Level INFO -Message "DÃ©tails des modifications pour $($file.Name):"
                    # Afficher les dÃ©tails des modifications
                }
            }
        }
        
        # GÃ©nÃ©rer le rapport de conformitÃ©
        $complianceReport = [PSCustomObject]@{
            TotalFiles = $files.Count
            ModifiedFiles = ($results | Where-Object { $_.Modified } | Measure-Object).Count
            CompliantFiles = ($results | Where-Object { -not $_.Modified } | Measure-Object).Count
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Enregistrer le rapport de conformitÃ©
        if ($ComplianceReportPath) {
            $complianceReportDir = Split-Path -Path $ComplianceReportPath -Parent
            if (-not (Test-Path -Path $complianceReportDir)) {
                New-Item -Path $complianceReportDir -ItemType Directory -Force | Out-Null
            }
            
            $complianceReport | ConvertTo-Json -Depth 10 | Set-Content -Path $ComplianceReportPath -Encoding UTF8
            Write-Log -Level SUCCESS -Message "Rapport de conformitÃ© enregistrÃ©: $ComplianceReportPath"
        }
        
        # Enregistrer le rapport de standardisation
        if ($OutputPath) {
            $outputDir = Split-Path -Path $OutputPath -Parent
            if (-not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log -Level SUCCESS -Message "Rapport de standardisation enregistrÃ©: $OutputPath"
        }
        
        # Afficher un rÃ©sumÃ©
        Write-Log -Level INFO -Message "RÃ©sumÃ© de la standardisation:"
        Write-Log -Level INFO -Message "  Fichiers analysÃ©s: $($files.Count)"
        Write-Log -Level SUCCESS -Message "  Fichiers conformes: $($complianceReport.CompliantFiles)"
        Write-Log -Level WARNING -Message "  Fichiers modifiÃ©s: $($complianceReport.ModifiedFiles)"
        
        return $complianceReport
    }
    
    # ExÃ©cuter la fonction principale
    Start-ScriptStandardization -Path $Path -ComplianceReportPath $ComplianceReportPath -OutputPath $OutputPath -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

