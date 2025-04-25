#Requires -Version 5.1
<#
.SYNOPSIS
    Teste la compatibilité des scripts PowerShell avec PowerShell 7.
.DESCRIPTION
    Ce script analyse les scripts PowerShell pour détecter les problèmes de compatibilité
    avec PowerShell 7 et suggère des corrections.
.PARAMETER Path
    Chemin du dossier ou fichier à analyser.
.PARAMETER Recursive
    Analyse récursivement les sous-dossiers.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER Fix
    Tente de corriger automatiquement les problèmes de compatibilité.
.EXAMPLE
    .\Test-PSVersionCompatibility.ps1 -Path ".\scripts" -Recursive -OutputPath ".\reports\ps7_compatibility.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\ps7_compatibility.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Fix
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour détecter les problèmes de compatibilité
function Find-CompatibilityIssues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return @()
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $ScriptPath -Raw
    $lines = Get-Content -Path $ScriptPath
    
    # Liste des problèmes de compatibilité
    $issues = @()
    
    # 1. Vérifier l'utilisation de cmdlets obsolètes
    $deprecatedCmdlets = @(
        @{
            Pattern = "Add-PSSnapin"
            Replacement = "Import-Module"
            Description = "Add-PSSnapin est obsolète dans PowerShell 7. Utilisez Import-Module à la place."
        },
        @{
            Pattern = "Export-Console"
            Replacement = "N/A"
            Description = "Export-Console est obsolète dans PowerShell 7 et n'a pas d'équivalent direct."
        },
        @{
            Pattern = "Get-WmiObject"
            Replacement = "Get-CimInstance"
            Description = "Get-WmiObject est obsolète dans PowerShell 7. Utilisez Get-CimInstance à la place."
        },
        @{
            Pattern = "Invoke-WmiMethod"
            Replacement = "Invoke-CimMethod"
            Description = "Invoke-WmiMethod est obsolète dans PowerShell 7. Utilisez Invoke-CimMethod à la place."
        },
        @{
            Pattern = "Register-WmiEvent"
            Replacement = "Register-CimIndicationEvent"
            Description = "Register-WmiEvent est obsolète dans PowerShell 7. Utilisez Register-CimIndicationEvent à la place."
        },
        @{
            Pattern = "Remove-WmiObject"
            Replacement = "Remove-CimInstance"
            Description = "Remove-WmiObject est obsolète dans PowerShell 7. Utilisez Remove-CimInstance à la place."
        },
        @{
            Pattern = "Set-WmiInstance"
            Replacement = "Set-CimInstance"
            Description = "Set-WmiInstance est obsolète dans PowerShell 7. Utilisez Set-CimInstance à la place."
        }
    )
    
    foreach ($cmdlet in $deprecatedCmdlets) {
        $matches = [regex]::Matches($content, "(?<![a-zA-Z0-9_-])$($cmdlet.Pattern)(?![a-zA-Z0-9_-])")
        
        foreach ($match in $matches) {
            $lineNumber = 0
            $line = ""
            
            # Trouver le numéro de ligne
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match [regex]::Escape($match.Value)) {
                    $lineNumber = $i + 1
                    $line = $lines[$i]
                    break
                }
            }
            
            $issues += [PSCustomObject]@{
                Type = "DeprecatedCmdlet"
                Description = $cmdlet.Description
                LineNumber = $lineNumber
                Line = $line
                Replacement = $cmdlet.Replacement
                Pattern = $cmdlet.Pattern
                Severity = "High"
            }
        }
    }
    
    # 2. Vérifier l'utilisation de $null à droite des comparaisons
    $nullComparisons = [regex]::Matches($content, "([a-zA-Z0-9_\[\]\.\$\{\}]+)\s+(?:-eq|-ne|-gt|-lt|-ge|-le)\s+\$null")
    
    foreach ($match in $nullComparisons) {
        $lineNumber = 0
        $line = ""
        
        # Trouver le numéro de ligne
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match [regex]::Escape($match.Value)) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                break
            }
        }
        
        $variable = $match.Groups[1].Value
        $operator = $line -match "-eq" ? "-eq" : ($line -match "-ne" ? "-ne" : ($line -match "-gt" ? "-gt" : ($line -match "-lt" ? "-lt" : ($line -match "-ge" ? "-ge" : "-le"))))
        
        $issues += [PSCustomObject]@{
            Type = "NullComparison"
            Description = "Comparaison avec `$null à droite. Dans PowerShell 7, il est recommandé de placer `$null à gauche pour éviter des problèmes avec les collections."
            LineNumber = $lineNumber
            Line = $line
            Replacement = "`$null $operator $variable"
            Pattern = "$variable $operator `$null"
            Severity = "Medium"
        }
    }
    
    # 3. Vérifier l'utilisation de SupportsShouldProcess sans $true
    $shouldProcessMatches = [regex]::Matches($content, "\[CmdletBinding\(SupportsShouldProcess\)\]")
    
    foreach ($match in $shouldProcessMatches) {
        $lineNumber = 0
        $line = ""
        
        # Trouver le numéro de ligne
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match [regex]::Escape($match.Value)) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                break
            }
        }
        
        $issues += [PSCustomObject]@{
            Type = "SupportsShouldProcess"
            Description = "SupportsShouldProcess sans valeur explicite. Dans PowerShell 7, il est recommandé d'utiliser SupportsShouldProcess=`$true."
            LineNumber = $lineNumber
            Line = $line
            Replacement = "[CmdletBinding(SupportsShouldProcess=`$true)]"
            Pattern = "[CmdletBinding(SupportsShouldProcess)]"
            Severity = "Low"
        }
    }
    
    # 4. Vérifier l'utilisation de variables non utilisées
    $variableDeclarations = [regex]::Matches($content, "\$([a-zA-Z0-9_]+)\s*=")
    
    foreach ($declaration in $variableDeclarations) {
        $variableName = $declaration.Groups[1].Value
        
        # Ignorer les variables courantes
        if ($variableName -in @("_", "PSItem", "args", "input", "PSBoundParameters", "PSScriptRoot", "PSCommandPath", "MyInvocation", "PSCmdlet", "PSDebugContext", "PSModuleInfo", "PSVersionTable")) {
            continue
        }
        
        # Vérifier si la variable est utilisée ailleurs dans le script
        $usageCount = [regex]::Matches($content, "\$($variableName)(?!\s*=)").Count
        
        if ($usageCount -eq 0) {
            $lineNumber = 0
            $line = ""
            
            # Trouver le numéro de ligne
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "\$($variableName)\s*=") {
                    $lineNumber = $i + 1
                    $line = $lines[$i]
                    break
                }
            }
            
            $issues += [PSCustomObject]@{
                Type = "UnusedVariable"
                Description = "Variable `$$variableName déclarée mais non utilisée. PowerShell 7 est plus strict concernant les variables non utilisées."
                LineNumber = $lineNumber
                Line = $line
                Replacement = "# $line"
                Pattern = $line
                Severity = "Low"
            }
        }
    }
    
    # 5. Vérifier l'utilisation de cmdlets avec des paramètres obsolètes
    $deprecatedParameters = @(
        @{
            Cmdlet = "Invoke-RestMethod"
            Parameter = "-UseDefaultCredentials"
            Replacement = "-Authentication Default"
            Description = "Le paramètre -UseDefaultCredentials est obsolète dans PowerShell 7. Utilisez -Authentication Default à la place."
        },
        @{
            Cmdlet = "Invoke-WebRequest"
            Parameter = "-UseDefaultCredentials"
            Replacement = "-Authentication Default"
            Description = "Le paramètre -UseDefaultCredentials est obsolète dans PowerShell 7. Utilisez -Authentication Default à la place."
        }
    )
    
    foreach ($param in $deprecatedParameters) {
        $matches = [regex]::Matches($content, "$($param.Cmdlet).*$($param.Parameter)")
        
        foreach ($match in $matches) {
            $lineNumber = 0
            $line = ""
            
            # Trouver le numéro de ligne
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match [regex]::Escape($match.Value)) {
                    $lineNumber = $i + 1
                    $line = $lines[$i]
                    break
                }
            }
            
            $issues += [PSCustomObject]@{
                Type = "DeprecatedParameter"
                Description = $param.Description
                LineNumber = $lineNumber
                Line = $line
                Replacement = $line -replace $param.Parameter, $param.Replacement
                Pattern = $param.Parameter
                Severity = "Medium"
            }
        }
    }
    
    # 6. Vérifier l'utilisation de .NET Framework au lieu de .NET Core
    $netFrameworkClasses = @(
        @{
            Pattern = "System\.Web\."
            Replacement = "N/A"
            Description = "Utilisation de System.Web qui n'est pas disponible dans .NET Core. Recherchez des alternatives compatibles avec .NET Core."
        },
        @{
            Pattern = "System\.Windows\.Forms\."
            Replacement = "N/A"
            Description = "Utilisation de System.Windows.Forms qui n'est pas entièrement compatible avec .NET Core. Envisagez d'utiliser des alternatives multiplateformes."
        },
        @{
            Pattern = "System\.Drawing\."
            Replacement = "N/A"
            Description = "Utilisation de System.Drawing qui n'est pas entièrement compatible avec .NET Core. Envisagez d'utiliser System.Drawing.Common ou d'autres alternatives."
        }
    )
    
    foreach ($class in $netFrameworkClasses) {
        $matches = [regex]::Matches($content, $class.Pattern)
        
        foreach ($match in $matches) {
            $lineNumber = 0
            $line = ""
            
            # Trouver le numéro de ligne
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match [regex]::Escape($match.Value)) {
                    $lineNumber = $i + 1
                    $line = $lines[$i]
                    break
                }
            }
            
            $issues += [PSCustomObject]@{
                Type = "NetFrameworkClass"
                Description = $class.Description
                LineNumber = $lineNumber
                Line = $line
                Replacement = $class.Replacement
                Pattern = $class.Pattern
                Severity = "High"
            }
        }
    }
    
    return $issues
}

# Fonction pour corriger les problèmes de compatibilité
function Fix-CompatibilityIssues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [array]$Issues
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $ScriptPath -Raw
    
    # Créer une copie de sauvegarde
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    
    # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
    $sortedIssues = $Issues | Sort-Object -Property LineNumber -Descending
    
    # Appliquer les corrections
    $modified = $false
    
    foreach ($issue in $sortedIssues) {
        if ($issue.Replacement -ne "N/A") {
            try {
                # Remplacer le problème
                $pattern = [regex]::Escape($issue.Pattern)
                $replacement = $issue.Replacement
                
                if ($content -match $pattern) {
                    $content = $content -replace $pattern, $replacement
                    $modified = $true
                    
                    Write-Log "Correction appliquée: Ligne $($issue.LineNumber) - $($issue.Type)" -Level "SUCCESS"
                }
                else {
                    Write-Log "Impossible de trouver le motif à remplacer: $($issue.Pattern)" -Level "WARNING"
                }
            }
            catch {
                Write-Log "Erreur lors de la correction: $_" -Level "ERROR"
            }
        }
        else {
            Write-Log "Aucune correction automatique disponible pour: Ligne $($issue.LineNumber) - $($issue.Type)" -Level "WARNING"
        }
    }
    
    # Enregistrer les modifications
    if ($modified) {
        $content | Out-File -FilePath $ScriptPath -Encoding utf8
        Write-Log "Script corrigé et enregistré: $ScriptPath (sauvegarde: $backupPath)" -Level "SUCCESS"
        return $true
    }
    else {
        Write-Log "Aucune modification apportée au script: $ScriptPath" -Level "INFO"
        Remove-Item -Path $backupPath -Force
        return $false
    }
}

# Fonction principale
function Start-PSVersionCompatibilityTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Fix
    )
    
    Write-Log "Démarrage du test de compatibilité PowerShell 7..." -Level "TITLE"
    Write-Log "Chemin: $Path"
    Write-Log "Récursif: $Recursive"
    Write-Log "Correction automatique: $Fix"
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le chemin n'existe pas: $Path" -Level "ERROR"
        return
    }
    
    # Obtenir les fichiers PowerShell
    $files = @()
    
    if (Test-Path -Path $Path -PathType Container) {
        # C'est un dossier
        $searchOptions = @{
            Path = $Path
            Filter = "*.ps1"
            File = $true
        }
        
        if ($Recursive) {
            $searchOptions.Recurse = $true
        }
        
        $files = Get-ChildItem @searchOptions
    }
    else {
        # C'est un fichier
        $files = Get-Item -Path $Path
    }
    
    Write-Log "Nombre de fichiers PowerShell à analyser: $($files.Count)"
    
    # Analyser les fichiers
    $results = @()
    $totalIssues = 0
    $fixedFiles = 0
    
    foreach ($file in $files) {
        Write-Log "Analyse du script: $($file.FullName)"
        
        $issues = Find-CompatibilityIssues -ScriptPath $file.FullName
        
        $totalIssues += $issues.Count
        
        if ($issues.Count -gt 0) {
            Write-Log "Problèmes de compatibilité détectés: $($issues.Count)" -Level "WARNING"
            
            foreach ($issue in $issues) {
                Write-Log "- Ligne $($issue.LineNumber): $($issue.Description)" -Level "WARNING"
            }
            
            if ($Fix) {
                $fixed = Fix-CompatibilityIssues -ScriptPath $file.FullName -Issues $issues
                
                if ($fixed) {
                    $fixedFiles++
                }
            }
        }
        else {
            Write-Log "Aucun problème de compatibilité détecté." -Level "SUCCESS"
        }
        
        $results += [PSCustomObject]@{
            Path = $file.FullName
            Name = $file.Name
            IssuesCount = $issues.Count
            Issues = $issues
            Fixed = if ($Fix) { $fixed } else { $false }
        }
    }
    
    # Générer le rapport
    if ($OutputPath) {
        $report = @{
            GeneratedAt = (Get-Date).ToString("o")
            Path = $Path
            Recursive = $Recursive
            TotalFiles = $files.Count
            TotalIssues = $totalIssues
            FixedFiles = $fixedFiles
            Results = $results
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
        
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer le rapport
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Log "Rapport généré: $OutputPath" -Level "SUCCESS"
    }
    
    # Afficher le résumé
    Write-Log "Résumé:" -Level "TITLE"
    Write-Log "Fichiers analysés: $($files.Count)"
    Write-Log "Problèmes détectés: $totalIssues"
    
    if ($Fix) {
        Write-Log "Fichiers corrigés: $fixedFiles"
    }
    
    return $results
}

# Exécuter la fonction principale
Start-PSVersionCompatibilityTest -Path $Path -Recursive:$Recursive -OutputPath $OutputPath -Fix:$Fix
