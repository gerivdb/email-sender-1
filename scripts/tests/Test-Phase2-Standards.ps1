<#
.SYNOPSIS
    Teste la Phase 2 : Standardisation des scripts.
.DESCRIPTION
    Ce script teste spécifiquement la Phase 2 du projet de réorganisation des scripts,
    qui concerne la standardisation des scripts. Il vérifie que les scripts sont conformes
    aux standards de codage définis.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par défaut: scripts\tests\standards_test_report.json
.PARAMETER ScriptType
    Type de script à tester (All, PowerShell, Python, Batch, Shell). Par défaut: All
.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Test-Phase2-Standards.ps1
    Teste la Phase 2 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase2-Standards.ps1 -Path "scripts\maintenance" -ScriptType PowerShell -Verbose
    Teste la Phase 2 sur les scripts PowerShell du dossier "scripts\maintenance" avec des informations détaillées.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\standards_test_report.json",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
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

# Fonction pour obtenir tous les fichiers de script
function Get-ScriptFiles {
    param (
        [string]$Path,
        [string]$ScriptType
    )
    
    $ScriptExtensions = @{
        "PowerShell" = @("*.ps1", "*.psm1", "*.psd1")
        "Python" = @("*.py")
        "Batch" = @("*.cmd", "*.bat")
        "Shell" = @("*.sh")
    }
    
    $Files = @()
    
    if ($ScriptType -eq "All") {
        foreach ($Type in $ScriptExtensions.Keys) {
            foreach ($Extension in $ScriptExtensions[$Type]) {
                $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
            }
        }
    } else {
        foreach ($Extension in $ScriptExtensions[$ScriptType]) {
            $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
        }
    }
    
    return $Files
}

# Fonction pour déterminer le type de script
function Get-ScriptType {
    param (
        [string]$FilePath
    )
    
    $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    switch ($Extension) {
        ".ps1" { return "PowerShell" }
        ".psm1" { return "PowerShell" }
        ".psd1" { return "PowerShell" }
        ".py" { return "Python" }
        ".cmd" { return "Batch" }
        ".bat" { return "Batch" }
        ".sh" { return "Shell" }
        default { return "Unknown" }
    }
}

# Fonction pour vérifier l'en-tête du script
function Test-ScriptHeader {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $Issues = @()
    
    switch ($ScriptType) {
        "PowerShell" {
            # Vérifier la présence d'un bloc de commentaires
            if (-not ($Content -match "<#[\s\S]*?#>")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tête"
                    Severity = "High"
                }
            } else {
                # Vérifier les éléments requis dans l'en-tête
                $null = $Content -match "<#[\s\S]*?#>"
                $HeaderContent = $Matches[0]
                
                if (-not ($HeaderContent -match "\.SYNOPSIS")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas de section SYNOPSIS"
                        Severity = "Medium"
                    }
                }
                
                if (-not ($HeaderContent -match "\.DESCRIPTION")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas de section DESCRIPTION"
                        Severity = "Medium"
                    }
                }
            }
        }
        "Python" {
            # Vérifier la présence d'un docstring
            if (-not ($Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de docstring d'en-tête"
                    Severity = "High"
                }
            }
        }
        "Batch" {
            # Vérifier la présence de commentaires d'en-tête
            if (-not ($Content -match "::[-]+\r?\n::([\s\S]*?)::[-]+")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tête"
                    Severity = "High"
                }
            }
        }
        "Shell" {
            # Vérifier la présence d'un shebang
            if (-not ($Content -match "^#!/bin/(ba)?sh")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne commence pas par un shebang (#!/bin/bash ou #!/bin/sh)"
                    Severity = "High"
                }
            }
        }
    }
    
    return $Issues
}

# Fonction pour vérifier le style de code
function Test-CodeStyle {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $ContentLines = Get-Content -Path $FilePath -Encoding UTF8
    $Issues = @()
    
    # Vérifier la longueur des lignes
    for ($i = 0; $i -lt $ContentLines.Count; $i++) {
        $LineNumber = $i + 1
        $Line = $ContentLines[$i]
        
        if ($Line.Length -gt 120) {
            $Issues += [PSCustomObject]@{
                Rule = "LineLength"
                Description = "La ligne $LineNumber dépasse 120 caractères (${$Line.Length})"
                Severity = "Low"
                LineNumber = $LineNumber
            }
        }
    }
    
    # Vérifications spécifiques au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Vérifier les comparaisons avec $null
            $NullComparisons = [regex]::Matches($Content, "(\`$[A-Za-z0-9_]+)\s+-eq\s+\`$null")
            foreach ($Comparison in $NullComparisons) {
                $Issues += [PSCustomObject]@{
                    Rule = "NullComparison"
                    Description = "Comparaison avec `$null incorrecte: '$($Comparison.Value)'. Utilisez plutôt: `$null -eq $($Comparison.Groups[1].Value)"
                    Severity = "Medium"
                }
            }
        }
        "Python" {
            # Vérifier l'utilisation de if __name__ == "__main__"
            if (-not ($Content -match 'if\s+__name__\s*==\s*[''"]__main__[''"]')) {
                $Issues += [PSCustomObject]@{
                    Rule = "MainGuard"
                    Description = "Le script ne contient pas de clause 'if __name__ == `"__main__`"'"
                    Severity = "Medium"
                }
            }
            
            # Vérifier l'indentation (espaces vs tabs)
            if ($Content -match "\t") {
                $Issues += [PSCustomObject]@{
                    Rule = "Indentation"
                    Description = "Le script utilise des tabulations au lieu d'espaces pour l'indentation"
                    Severity = "Medium"
                }
            }
        }
        "Batch" {
            # Vérifier l'utilisation de @echo off
            if (-not ($Content -match "^@echo off")) {
                $Issues += [PSCustomObject]@{
                    Rule = "EchoOff"
                    Description = "Le script ne commence pas par '@echo off'"
                    Severity = "Medium"
                }
            }
        }
        "Shell" {
            # Vérifier l'utilisation de set -e
            if (-not ($Content -match "set -e")) {
                $Issues += [PSCustomObject]@{
                    Rule = "SetE"
                    Description = "Le script n'utilise pas 'set -e' pour arrêter en cas d'erreur"
                    Severity = "Medium"
                }
            }
        }
    }
    
    return $Issues
}

# Fonction pour vérifier l'encodage du fichier
function Test-FileEncoding {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Issues = @()
    
    # Lire les premiers octets du fichier pour détecter l'encodage
    $Bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $HasBOM = $false
    
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        $HasBOM = $true
    }
    
    switch ($ScriptType) {
        "PowerShell" {
            if (-not $HasBOM) {
                $Issues += [PSCustomObject]@{
                    Rule = "Encoding"
                    Description = "Le script PowerShell n'est pas encodé en UTF-8 avec BOM"
                    Severity = "Medium"
                }
            }
        }
        "Python" {
            if ($HasBOM) {
                $Issues += [PSCustomObject]@{
                    Rule = "Encoding"
                    Description = "Le script Python ne devrait pas avoir de BOM"
                    Severity = "Medium"
                }
            }
        }
        "Shell" {
            if ($HasBOM) {
                $Issues += [PSCustomObject]@{
                    Rule = "Encoding"
                    Description = "Le script Shell ne devrait pas avoir de BOM"
                    Severity = "Medium"
                }
            }
        }
    }
    
    return $Issues
}

# Fonction principale pour analyser un script
function Test-Script {
    param (
        [string]$FilePath
    )
    
    $ScriptType = Get-ScriptType -FilePath $FilePath
    
    if ($ScriptType -eq "Unknown") {
        Write-Log "Type de script inconnu: $FilePath" -Level "WARNING"
        return $null
    }
    
    $Issues = @()
    
    # Vérifier l'en-tête du script
    $HeaderIssues = Test-ScriptHeader -FilePath $FilePath -ScriptType $ScriptType
    $Issues += $HeaderIssues
    
    # Vérifier le style de code
    $StyleIssues = Test-CodeStyle -FilePath $FilePath -ScriptType $ScriptType
    $Issues += $StyleIssues
    
    # Vérifier l'encodage du fichier
    $EncodingIssues = Test-FileEncoding -FilePath $FilePath -ScriptType $ScriptType
    $Issues += $EncodingIssues
    
    $Result = [PSCustomObject]@{
        FilePath = $FilePath
        ScriptType = $ScriptType
        IssueCount = $Issues.Count
        HighSeverityCount = ($Issues | Where-Object { $_.Severity -eq "High" }).Count
        MediumSeverityCount = ($Issues | Where-Object { $_.Severity -eq "Medium" }).Count
        LowSeverityCount = ($Issues | Where-Object { $_.Severity -eq "Low" }).Count
        Issues = $Issues
    }
    
    return $Result
}

# Fonction principale
function Test-Standards {
    param (
        [string]$Path,
        [string]$OutputPath,
        [string]$ScriptType,
        [switch]$Verbose
    )
    
    Write-Log "=== Test de la Phase 2 : Standardisation des scripts ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "INFO"
    }
    
    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $Path -ScriptType $ScriptType
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers à analyser: $TotalFiles" -Level "INFO"
    
    # Initialiser les résultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $TotalFiles
        ScriptType = $ScriptType
        HighSeverityCount = 0
        MediumSeverityCount = 0
        LowSeverityCount = 0
        TotalIssueCount = 0
        ScriptResults = @()
    }
    
    # Analyser chaque fichier
    $FileCounter = 0
    foreach ($File in $ScriptFiles) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Analyse de conformité" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
        if ($Verbose) {
            Write-Log "Analyse du fichier: $($File.FullName)" -Level "INFO"
        }
        
        # Analyser le script
        $ScriptResult = Test-Script -FilePath $File.FullName
        
        if ($null -ne $ScriptResult) {
            $Results.ScriptResults += $ScriptResult
            $Results.HighSeverityCount += $ScriptResult.HighSeverityCount
            $Results.MediumSeverityCount += $ScriptResult.MediumSeverityCount
            $Results.LowSeverityCount += $ScriptResult.LowSeverityCount
            $Results.TotalIssueCount += $ScriptResult.IssueCount
            
            if ($Verbose -and $ScriptResult.IssueCount -gt 0) {
                Write-Log "  Problèmes trouvés: $($ScriptResult.IssueCount)" -Level "WARNING"
                foreach ($Issue in $ScriptResult.Issues) {
                    $SeverityColor = switch ($Issue.Severity) {
                        "High" { "ERROR" }
                        "Medium" { "WARNING" }
                        "Low" { "INFO" }
                    }
                    Write-Log "    [$($Issue.Severity)] $($Issue.Rule): $($Issue.Description)" -Level $SeverityColor
                }
            }
        }
    }
    
    Write-Progress -Activity "Analyse de conformité" -Completed
    
    # Enregistrer les résultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    Write-Log "Analyse terminée" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysés: $TotalFiles" -Level "INFO"
    Write-Log "Nombre total de problèmes trouvés: $($Results.TotalIssueCount)" -Level "INFO"
    Write-Log "  Problèmes de sévérité haute: $($Results.HighSeverityCount)" -Level $(if ($Results.HighSeverityCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "  Problèmes de sévérité moyenne: $($Results.MediumSeverityCount)" -Level $(if ($Results.MediumSeverityCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "  Problèmes de sévérité basse: $($Results.LowSeverityCount)" -Level "INFO"
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    
    # Déterminer si le test est réussi
    if ($Results.HighSeverityCount -gt 0) {
        Write-Log "Des problèmes de sévérité haute ont été détectés" -Level "WARNING"
        Write-Log "La Phase 2 n'a pas complètement réussi" -Level "WARNING"
        return $false
    } elseif ($Results.MediumSeverityCount -gt 10) {
        Write-Log "Un nombre important de problèmes de sévérité moyenne a été détecté" -Level "WARNING"
        Write-Log "La Phase 2 a partiellement réussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "Aucun problème majeur détecté" -Level "SUCCESS"
        Write-Log "La Phase 2 a réussi" -Level "SUCCESS"
        return $true
    }
}

# Exécuter le test
$Success = Test-Standards -Path $Path -OutputPath $OutputPath -ScriptType $ScriptType -Verbose:$Verbose

# Retourner le résultat
return $Success
