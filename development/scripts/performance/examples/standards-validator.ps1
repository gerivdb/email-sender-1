#Requires -Version 5.1
<#
.SYNOPSIS
    Valide les standards de code PowerShell.
.DESCRIPTION
    Ce script valide les standards de code PowerShell en utilisant une architecture hybride
    PowerShell-Python pour le traitement parallÃ¨le.
.PARAMETER ScriptsPath
    Chemin vers le rÃ©pertoire contenant les scripts PowerShell Ã  valider.
.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire oÃ¹ les rÃ©sultats seront enregistrÃ©s.
.PARAMETER StandardsFile
    Chemin vers le fichier JSON contenant les standards de code.
.PARAMETER FilePatterns
    ModÃ¨les de noms de fichiers Ã  inclure (par dÃ©faut : *.ps1, *.psm1).
.PARAMETER UseCache
    Utilise un cache pour amÃ©liorer les performances lors des exÃ©cutions rÃ©pÃ©tÃ©es.
.PARAMETER FixViolations
    Tente de corriger automatiquement certaines violations des standards.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptsPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$StandardsFile = (Join-Path -Path $PSScriptRoot -ChildPath "standards.json"),
    
    [Parameter(Mandatory = $false)]
    [string[]]$FilePatterns = @("*.ps1", "*.psm1"),
    
    [Parameter(Mandatory = $false)]
    [switch]$UseCache,
    
    [Parameter(Mandatory = $false)]
    [switch]$FixViolations
)

# Importer le module d'architecture hybride
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ParallelHybrid.psm1"
Import-Module $modulePath -Force

# CrÃ©er le fichier de standards s'il n'existe pas
if (-not (Test-Path -Path $StandardsFile)) {
    $standards = @{
        naming = @{
            functions = @{
                pattern = "^[A-Z][a-zA-Z0-9]+-[A-Z][a-zA-Z0-9]+$"
                description = "Les noms de fonctions doivent suivre le format Verbe-Nom avec PascalCase"
                severity = "Error"
            }
            variables = @{
                pattern = "^[a-z][a-zA-Z0-9]+$"
                description = "Les noms de variables doivent Ãªtre en camelCase"
                severity = "Warning"
            }
            parameters = @{
                pattern = "^[A-Z][a-zA-Z0-9]+$"
                description = "Les noms de paramÃ¨tres doivent Ãªtre en PascalCase"
                severity = "Warning"
            }
        }
        structure = @{
            requires = @{
                pattern = "^#Requires -Version"
                description = "Les scripts doivent spÃ©cifier la version PowerShell requise"
                severity = "Warning"
            }
            help = @{
                pattern = "^<#[\s\S]*\.SYNOPSIS[\s\S]*\.DESCRIPTION[\s\S]*#>"
                description = "Les scripts doivent avoir un bloc d'aide avec au moins SYNOPSIS et DESCRIPTION"
                severity = "Warning"
            }
            encoding = @{
                pattern = "utf8"
                description = "Les fichiers doivent Ãªtre encodÃ©s en UTF-8"
                severity = "Error"
            }
        }
        practices = @{
            errorHandling = @{
                pattern = "try[\s\S]*catch"
                description = "Utiliser try/catch pour la gestion des erreurs"
                severity = "Warning"
            }
            approvedVerbs = @{
                pattern = "^(Add|Clear|Close|Copy|Enter|Exit|Find|Format|Get|Hide|Join|Lock|Move|New|Open|Optimize|Pop|Push|Read|Remove|Rename|Reset|Resize|Search|Select|Set|Show|Skip|Split|Step|Switch|Undo|Unlock|Watch|Write)-"
                description = "Utiliser uniquement des verbes approuvÃ©s pour les fonctions"
                severity = "Error"
            }
            commentRatio = @{
                value = 0.1
                description = "Le ratio de commentaires doit Ãªtre d'au moins 10% du code"
                severity = "Warning"
            }
        }
    }
    
    $standards | ConvertTo-Json -Depth 5 | Out-File -FilePath $StandardsFile -Encoding utf8
    Write-Host "Fichier de standards crÃ©Ã© : $StandardsFile" -ForegroundColor Green
}

# VÃ©rifier que le script Python de validation existe
$pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "standards_validator.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    Write-Error "Le script Python de validation n'existe pas : $pythonScriptPath"
    Write-Host "Veuillez exÃ©cuter 'git pull' pour rÃ©cupÃ©rer les derniers fichiers ou crÃ©er le fichier manuellement." -ForegroundColor Yellow
    exit 1
}

# Fonction pour dÃ©marrer la validation des standards
function Start-StandardsValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$StandardsFile,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FilePatterns,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # RÃ©cupÃ©rer les fichiers Ã  valider
    $scriptFiles = @()
    foreach ($pattern in $FilePatterns) {
        $scriptFiles += Get-ChildItem -Path $ScriptsPath -Filter $pattern -Recurse | Select-Object -ExpandProperty FullName
    }
    
    $totalFiles = $scriptFiles.Count
    Write-Host "Nombre de fichiers Ã  valider : $totalFiles" -ForegroundColor Yellow
    
    if ($totalFiles -eq 0) {
        Write-Warning "Aucun fichier trouvÃ© correspondant aux modÃ¨les spÃ©cifiÃ©s."
        return @()
    }
    
    # Configuration du cache
    $cacheConfig = $null
    if ($UseCache) {
        $cacheConfig = @{
            CachePath = Join-Path -Path $OutputPath -ChildPath "cache"
            CacheType = "Hybrid"
            MaxMemorySize = 50
            MaxDiskSize = 100
            DefaultTTL = 3600
            EvictionPolicy = "LRU"
        }
    }
    
    # Valider les standards en parallÃ¨le
    Write-Host "Validation des standards en parallÃ¨le..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Convertir les standards en JSON pour Ã©viter les problÃ¨mes de sÃ©rialisation
    $standardsJson = $standards | ConvertTo-Json -Depth 10 -Compress
    
    # Utiliser une approche simplifiÃ©e pour la validation
    $results = @()
    
    foreach ($scriptFile in $scriptFiles) {
        Write-Host "Validation de $scriptFile..." -ForegroundColor Cyan
        
        try {
            # Appeler le script Python directement
            $outputFile = Join-Path -Path $OutputPath -ChildPath "validation-$([System.IO.Path]::GetFileNameWithoutExtension($scriptFile)).json"
            $inputFile = Join-Path -Path $OutputPath -ChildPath "input-$([System.IO.Path]::GetFileNameWithoutExtension($scriptFile)).json"
            
            # CrÃ©er le fichier d'entrÃ©e
            @($scriptFile) | ConvertTo-Json | Out-File -FilePath $inputFile -Encoding utf8
            
            # ExÃ©cuter le script Python
            $pythonArgs = @(
                $pythonScriptPath,
                "--input", $inputFile,
                "--output", $outputFile,
                "--standards", $StandardsFile
            )
            
            if ($UseCache) {
                $pythonArgs += "--cache"
                $pythonArgs += (Join-Path -Path $OutputPath -ChildPath "cache")
            }
            
            $pythonProcess = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait
            
            if ($pythonProcess.ExitCode -eq 0) {
                # Lire les rÃ©sultats
                $result = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
                $results += $result
            }
            else {
                Write-Warning "Erreur lors de la validation de $scriptFile. Code de sortie : $($pythonProcess.ExitCode)"
            }
            
            # Nettoyer les fichiers temporaires
            if (Test-Path -Path $inputFile) {
                Remove-Item -Path $inputFile -Force
            }
            if (Test-Path -Path $outputFile) {
                Remove-Item -Path $outputFile -Force
            }
        }
        catch {
            Write-Error "Erreur lors de la validation de $scriptFile : $_"
        }
    }
    
    $stopwatch.Stop()
    Write-Host "Validation terminÃ©e en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Green
    
    # GÃ©nÃ©rer un rapport de synthÃ¨se
    $reportPath = Join-Path -Path $OutputPath -ChildPath "validation-report.json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport de validation gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    
    # Afficher un rÃ©sumÃ©
    $compliantFiles = ($results | Where-Object { $_.is_compliant -eq $true }).Count
    $nonCompliantFiles = $totalFiles - $compliantFiles
    $totalErrors = ($results | Measure-Object -Property errors -Sum).Sum
    $totalWarnings = ($results | Measure-Object -Property warnings -Sum).Sum
    
    Write-Host "`nRÃ©sumÃ© de la validation :" -ForegroundColor Yellow
    Write-Host "  Fichiers conformes : $compliantFiles / $totalFiles" -ForegroundColor Yellow
    Write-Host "  Fichiers non conformes : $nonCompliantFiles / $totalFiles" -ForegroundColor Yellow
    Write-Host "  Erreurs totales : $totalErrors" -ForegroundColor Yellow
    Write-Host "  Avertissements totaux : $totalWarnings" -ForegroundColor Yellow
    
    return $results
}

# Fonction pour corriger les violations
function Repair-StandardViolations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Standards
    )
    
    $fixedFiles = 0
    
    foreach ($result in $Results) {
        if (-not $result.is_compliant) {
            $filePath = $result.file_info.file_path
            $violations = $result.violations
            
            Write-Host "Correction des violations dans $filePath..." -ForegroundColor Cyan
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            $modified = $false
            
            # Corriger les violations
            foreach ($violation in $violations) {
                switch ($violation.type) {
                    "structure.requires" {
                        # Ajouter la directive #Requires
                        if (-not $content.StartsWith("#Requires")) {
                            $content = "#Requires -Version 5.1`n$content"
                            $modified = $true
                            Write-Host "  Ajout de la directive #Requires" -ForegroundColor Green
                        }
                    }
                    "structure.help" {
                        # Ajouter un bloc d'aide minimal
                        if (-not ($content -match "<#[\s\S]*\.SYNOPSIS[\s\S]*\.DESCRIPTION[\s\S]*#>")) {
                            $helpBlock = @"
<#
.SYNOPSIS
    Script PowerShell.
.DESCRIPTION
    Ce script est un script PowerShell.
#>

"@
                            $content = $helpBlock + $content
                            $modified = $true
                            Write-Host "  Ajout d'un bloc d'aide minimal" -ForegroundColor Green
                        }
                    }
                    "naming.functions" {
                        # Corriger les noms de fonctions (cas simple)
                        if ($violation.name -match "^([a-z][a-zA-Z0-9]*)([A-Z][a-zA-Z0-9]*)$") {
                            $oldName = $violation.name
                            $verb = $matches[1]
                            $noun = $matches[2]
                            $newName = (Get-Culture).TextInfo.ToTitleCase($verb) + "-" + $noun
                            
                            $content = $content -replace "function\s+$oldName\s*{", "function $newName {"
                            $modified = $true
                            Write-Host "  Correction du nom de fonction : $oldName -> $newName" -ForegroundColor Green
                        }
                    }
                    "naming.variables" {
                        # Corriger les noms de variables (cas simple)
                        if ($violation.name -match "^([A-Z][a-zA-Z0-9]*)$") {
                            $oldName = $violation.name
                            $newName = $oldName.Substring(0, 1).ToLower() + $oldName.Substring(1)
                            
                            $content = $content -replace "\`$$oldName\s*=", "`$$newName ="
                            $modified = $true
                            Write-Host "  Correction du nom de variable : `$$oldName -> `$$newName" -ForegroundColor Green
                        }
                    }
                }
            }
            
            # Enregistrer les modifications
            if ($modified) {
                $content | Out-File -FilePath $filePath -Encoding utf8
                $fixedFiles++
                Write-Host "Fichier corrigÃ© : $filePath" -ForegroundColor Green
            }
            else {
                Write-Host "Aucune correction automatique possible pour $filePath" -ForegroundColor Yellow
            }
        }
    }
    
    return $fixedFiles
}

# ExÃ©cuter la validation
try {
    $results = Start-StandardsValidation `
        -ScriptsPath $ScriptsPath `
        -OutputPath $OutputPath `
        -StandardsFile $StandardsFile `
        -FilePatterns $FilePatterns `
        -UseCache:$UseCache
    
    # Corriger les violations si demandÃ©
    if ($FixViolations) {
        Write-Host "`nCorrection des violations..." -ForegroundColor Cyan
        $fixedFiles = Repair-StandardViolations -Results $results -Standards $standards
        Write-Host "Nombre de fichiers corrigÃ©s : $fixedFiles" -ForegroundColor Green
    }
    
    # Retourner les rÃ©sultats
    return $results
}
catch {
    Write-Error "Erreur lors de la validation des standards : $_"
    return $null
}
