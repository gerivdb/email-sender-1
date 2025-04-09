<#
.SYNOPSIS
    Teste la Phase 2 : Standardisation des scripts.
.DESCRIPTION
    Ce script teste spÃ©cifiquement la Phase 2 du projet de rÃ©organisation des scripts,
    qui concerne la standardisation des scripts. Il vÃ©rifie que les scripts sont conformes
    aux standards de codage dÃ©finis.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par dÃ©faut: scripts\tests\standards_test_report.json
.PARAMETER ScriptType
    Type de script Ã  tester (All, PowerShell, Python, Batch, Shell). Par dÃ©faut: All
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-Phase2-Standards.ps1
    Teste la Phase 2 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase2-Standards.ps1 -Path "scripts\maintenance" -ScriptType PowerShell -Verbose
    Teste la Phase 2 sur les scripts PowerShell du dossier "scripts\maintenance" avec des informations dÃ©taillÃ©es.

<#
.SYNOPSIS
    Teste la Phase 2 : Standardisation des scripts.
.DESCRIPTION
    Ce script teste spÃ©cifiquement la Phase 2 du projet de rÃ©organisation des scripts,
    qui concerne la standardisation des scripts. Il vÃ©rifie que les scripts sont conformes
    aux standards de codage dÃ©finis.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  tester. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par dÃ©faut: scripts\tests\standards_test_report.json
.PARAMETER ScriptType
    Type de script Ã  tester (All, PowerShell, Python, Batch, Shell). Par dÃ©faut: All
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-Phase2-Standards.ps1
    Teste la Phase 2 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase2-Standards.ps1 -Path "scripts\maintenance" -ScriptType PowerShell -Verbose
    Teste la Phase 2 sur les scripts PowerShell du dossier "scripts\maintenance" avec des informations dÃ©taillÃ©es.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\standards_test_report.json",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")

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
]
    [string]$ScriptType = "All",
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

# Fonction pour dÃ©terminer le type de script
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

# Fonction pour vÃ©rifier l'en-tÃªte du script
function Test-ScriptHeader {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $Issues = @()
    
    switch ($ScriptType) {
        "PowerShell" {
            # VÃ©rifier la prÃ©sence d'un bloc de commentaires
            if (-not ($Content -match "<#[\s\S]*?#>")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tÃªte"
                    Severity = "High"
                }
            } else {
                # VÃ©rifier les Ã©lÃ©ments requis dans l'en-tÃªte
                $null = $Content -match "<#[\s\S]*?#>"
                $HeaderContent = $Matches[0]
                
                if (-not ($HeaderContent -match "\.SYNOPSIS")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas de section SYNOPSIS"
                        Severity = "Medium"
                    }
                }
                
                if (-not ($HeaderContent -match "\.DESCRIPTION")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas de section DESCRIPTION"
                        Severity = "Medium"
                    }
                }
            }
        }
        "Python" {
            # VÃ©rifier la prÃ©sence d'un docstring
            if (-not ($Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de docstring d'en-tÃªte"
                    Severity = "High"
                }
            }
        }
        "Batch" {
            # VÃ©rifier la prÃ©sence de commentaires d'en-tÃªte
            if (-not ($Content -match "::[-]+\r?\n::([\s\S]*?)::[-]+")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tÃªte"
                    Severity = "High"
                }
            }
        }
        "Shell" {
            # VÃ©rifier la prÃ©sence d'un shebang
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

# Fonction pour vÃ©rifier le style de code
function Test-CodeStyle {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $ContentLines = Get-Content -Path $FilePath -Encoding UTF8
    $Issues = @()
    
    # VÃ©rifier la longueur des lignes
    for ($i = 0; $i -lt $ContentLines.Count; $i++) {
        $LineNumber = $i + 1
        $Line = $ContentLines[$i]
        
        if ($Line.Length -gt 120) {
            $Issues += [PSCustomObject]@{
                Rule = "LineLength"
                Description = "La ligne $LineNumber dÃ©passe 120 caractÃ¨res (${$Line.Length})"
                Severity = "Low"
                LineNumber = $LineNumber
            }
        }
    }
    
    # VÃ©rifications spÃ©cifiques au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # VÃ©rifier les comparaisons avec $null
            $NullComparisons = [regex]::Matches($Content, "(\`$[A-Za-z0-9_]+)\s+-eq\s+\`$null")
            foreach ($Comparison in $NullComparisons) {
                $Issues += [PSCustomObject]@{
                    Rule = "NullComparison"
                    Description = "Comparaison avec `$null incorrecte: '$($Comparison.Value)'. Utilisez plutÃ´t: `$null -eq $($Comparison.Groups[1].Value)"
                    Severity = "Medium"
                }
            }
        }
        "Python" {
            # VÃ©rifier l'utilisation de if __name__ == "__main__"
            if (-not ($Content -match 'if\s+__name__\s*==\s*[''"]__main__[''"]')) {
                $Issues += [PSCustomObject]@{
                    Rule = "MainGuard"
                    Description = "Le script ne contient pas de clause 'if __name__ == `"__main__`"'"
                    Severity = "Medium"
                }
            }
            
            # VÃ©rifier l'indentation (espaces vs tabs)
            if ($Content -match "\t") {
                $Issues += [PSCustomObject]@{
                    Rule = "Indentation"
                    Description = "Le script utilise des tabulations au lieu d'espaces pour l'indentation"
                    Severity = "Medium"
                }
            }
        }
        "Batch" {
            # VÃ©rifier l'utilisation de @echo off
            if (-not ($Content -match "^@echo off")) {
                $Issues += [PSCustomObject]@{
                    Rule = "EchoOff"
                    Description = "Le script ne commence pas par '@echo off'"
                    Severity = "Medium"
                }
            }
        }
        "Shell" {
            # VÃ©rifier l'utilisation de set -e
            if (-not ($Content -match "set -e")) {
                $Issues += [PSCustomObject]@{
                    Rule = "SetE"
                    Description = "Le script n'utilise pas 'set -e' pour arrÃªter en cas d'erreur"
                    Severity = "Medium"
                }
            }
        }
    }
    
    return $Issues
}

# Fonction pour vÃ©rifier l'encodage du fichier
function Test-FileEncoding {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Issues = @()
    
    # Lire les premiers octets du fichier pour dÃ©tecter l'encodage
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
                    Description = "Le script PowerShell n'est pas encodÃ© en UTF-8 avec BOM"
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
    
    # VÃ©rifier l'en-tÃªte du script
    $HeaderIssues = Test-ScriptHeader -FilePath $FilePath -ScriptType $ScriptType
    $Issues += $HeaderIssues
    
    # VÃ©rifier le style de code
    $StyleIssues = Test-CodeStyle -FilePath $FilePath -ScriptType $ScriptType
    $Issues += $StyleIssues
    
    # VÃ©rifier l'encodage du fichier
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
    Write-Log "Chemin des scripts Ã  tester: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "INFO"
    }
    
    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $Path -ScriptType $ScriptType
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers Ã  analyser: $TotalFiles" -Level "INFO"
    
    # Initialiser les rÃ©sultats
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
        Write-Progress -Activity "Analyse de conformitÃ©" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
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
                Write-Log "  ProblÃ¨mes trouvÃ©s: $($ScriptResult.IssueCount)" -Level "WARNING"
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
    
    Write-Progress -Activity "Analyse de conformitÃ©" -Completed
    
    # Enregistrer les rÃ©sultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    Write-Log "Analyse terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysÃ©s: $TotalFiles" -Level "INFO"
    Write-Log "Nombre total de problÃ¨mes trouvÃ©s: $($Results.TotalIssueCount)" -Level "INFO"
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© haute: $($Results.HighSeverityCount)" -Level $(if ($Results.HighSeverityCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© moyenne: $($Results.MediumSeverityCount)" -Level $(if ($Results.MediumSeverityCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© basse: $($Results.LowSeverityCount)" -Level "INFO"
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    # DÃ©terminer si le test est rÃ©ussi
    if ($Results.HighSeverityCount -gt 0) {
        Write-Log "Des problÃ¨mes de sÃ©vÃ©ritÃ© haute ont Ã©tÃ© dÃ©tectÃ©s" -Level "WARNING"
        Write-Log "La Phase 2 n'a pas complÃ¨tement rÃ©ussi" -Level "WARNING"
        return $false
    } elseif ($Results.MediumSeverityCount -gt 10) {
        Write-Log "Un nombre important de problÃ¨mes de sÃ©vÃ©ritÃ© moyenne a Ã©tÃ© dÃ©tectÃ©" -Level "WARNING"
        Write-Log "La Phase 2 a partiellement rÃ©ussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "Aucun problÃ¨me majeur dÃ©tectÃ©" -Level "SUCCESS"
        Write-Log "La Phase 2 a rÃ©ussi" -Level "SUCCESS"
        return $true
    }
}

# ExÃ©cuter le test
$Success = Test-Standards -Path $Path -OutputPath $OutputPath -ScriptType $ScriptType -Verbose:$Verbose

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
