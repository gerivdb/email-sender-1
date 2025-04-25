#Requires -Version 5.1
<#
.SYNOPSIS
    Valide les standards de code PowerShell.
.DESCRIPTION
    Ce script valide les standards de code PowerShell en utilisant une architecture hybride
    PowerShell-Python pour le traitement parallèle.
.PARAMETER ScriptsPath
    Chemin vers le répertoire contenant les scripts PowerShell à valider.
.PARAMETER OutputPath
    Chemin vers le répertoire où les résultats seront enregistrés.
.PARAMETER StandardsFile
    Chemin vers le fichier JSON contenant les standards de code.
.PARAMETER FilePatterns
    Modèles de noms de fichiers à inclure (par défaut : *.ps1, *.psm1).
.PARAMETER UseCache
    Utilise un cache pour améliorer les performances lors des exécutions répétées.
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

# Créer le fichier de standards s'il n'existe pas
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
                description = "Les noms de variables doivent être en camelCase"
                severity = "Warning"
            }
            parameters = @{
                pattern = "^[A-Z][a-zA-Z0-9]+$"
                description = "Les noms de paramètres doivent être en PascalCase"
                severity = "Warning"
            }
        }
        structure = @{
            requires = @{
                pattern = "^#Requires -Version"
                description = "Les scripts doivent spécifier la version PowerShell requise"
                severity = "Warning"
            }
            help = @{
                pattern = "^<#[\s\S]*\.SYNOPSIS[\s\S]*\.DESCRIPTION[\s\S]*#>"
                description = "Les scripts doivent avoir un bloc d'aide avec au moins SYNOPSIS et DESCRIPTION"
                severity = "Warning"
            }
            encoding = @{
                pattern = "utf8"
                description = "Les fichiers doivent être encodés en UTF-8"
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
                description = "Utiliser uniquement des verbes approuvés pour les fonctions"
                severity = "Error"
            }
            commentRatio = @{
                value = 0.1
                description = "Le ratio de commentaires doit être d'au moins 10% du code"
                severity = "Warning"
            }
        }
    }
    
    $standards | ConvertTo-Json -Depth 5 | Out-File -FilePath $StandardsFile -Encoding utf8
    Write-Host "Fichier de standards créé : $StandardsFile" -ForegroundColor Green
}

# Vérifier que le script Python de validation existe
$pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "standards_validator.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    Write-Error "Le script Python de validation n'existe pas : $pythonScriptPath"
    Write-Host "Veuillez exécuter 'git pull' pour récupérer les derniers fichiers ou créer le fichier manuellement." -ForegroundColor Yellow
    exit 1
}

# Fonction pour démarrer la validation des standards
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
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Récupérer les fichiers à valider
    $scriptFiles = @()
    foreach ($pattern in $FilePatterns) {
        $scriptFiles += Get-ChildItem -Path $ScriptsPath -Filter $pattern -Recurse | Select-Object -ExpandProperty FullName
    }
    
    $totalFiles = $scriptFiles.Count
    Write-Host "Nombre de fichiers à valider : $totalFiles" -ForegroundColor Yellow
    
    if ($totalFiles -eq 0) {
        Write-Warning "Aucun fichier trouvé correspondant aux modèles spécifiés."
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
    
    # Valider les standards en parallèle
    Write-Host "Validation des standards en parallèle..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Convertir les standards en JSON pour éviter les problèmes de sérialisation
    $standardsJson = $standards | ConvertTo-Json -Depth 10 -Compress
    
    # Utiliser une approche simplifiée pour la validation
    $results = @()
    
    foreach ($scriptFile in $scriptFiles) {
        Write-Host "Validation de $scriptFile..." -ForegroundColor Cyan
        
        try {
            # Appeler le script Python directement
            $outputFile = Join-Path -Path $OutputPath -ChildPath "validation-$([System.IO.Path]::GetFileNameWithoutExtension($scriptFile)).json"
            $inputFile = Join-Path -Path $OutputPath -ChildPath "input-$([System.IO.Path]::GetFileNameWithoutExtension($scriptFile)).json"
            
            # Créer le fichier d'entrée
            @($scriptFile) | ConvertTo-Json | Out-File -FilePath $inputFile -Encoding utf8
            
            # Exécuter le script Python
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
                # Lire les résultats
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
    Write-Host "Validation terminée en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Green
    
    # Générer un rapport de synthèse
    $reportPath = Join-Path -Path $OutputPath -ChildPath "validation-report.json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport de validation généré : $reportPath" -ForegroundColor Green
    
    # Afficher un résumé
    $compliantFiles = ($results | Where-Object { $_.is_compliant -eq $true }).Count
    $nonCompliantFiles = $totalFiles - $compliantFiles
    $totalErrors = ($results | Measure-Object -Property errors -Sum).Sum
    $totalWarnings = ($results | Measure-Object -Property warnings -Sum).Sum
    
    Write-Host "`nRésumé de la validation :" -ForegroundColor Yellow
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
                Write-Host "Fichier corrigé : $filePath" -ForegroundColor Green
            }
            else {
                Write-Host "Aucune correction automatique possible pour $filePath" -ForegroundColor Yellow
            }
        }
    }
    
    return $fixedFiles
}

# Exécuter la validation
try {
    $results = Start-StandardsValidation `
        -ScriptsPath $ScriptsPath `
        -OutputPath $OutputPath `
        -StandardsFile $StandardsFile `
        -FilePatterns $FilePatterns `
        -UseCache:$UseCache
    
    # Corriger les violations si demandé
    if ($FixViolations) {
        Write-Host "`nCorrection des violations..." -ForegroundColor Cyan
        $fixedFiles = Repair-StandardViolations -Results $results -Standards $standards
        Write-Host "Nombre de fichiers corrigés : $fixedFiles" -ForegroundColor Green
    }
    
    # Retourner les résultats
    return $results
}
catch {
    Write-Error "Erreur lors de la validation des standards : $_"
    return $null
}
