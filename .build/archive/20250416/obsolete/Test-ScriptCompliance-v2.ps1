<#
.SYNOPSIS
    Analyse la conformitÃ© des scripts aux standards de codage dÃ©finis.
.DESCRIPTION
    Ce script analyse les scripts PowerShell, Python, Batch et Shell pour vÃ©rifier
    leur conformitÃ© aux standards de codage dÃ©finis dans CodingStandards.md.
    Il gÃ©nÃ¨re un rapport dÃ©taillÃ© des problÃ¨mes trouvÃ©s.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par dÃ©faut: scripts\manager\data\compliance_report.json
.PARAMETER ScriptType
    Type de script Ã  analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1
    Analyse tous les scripts dans le dossier scripts et gÃ©nÃ¨re un rapport.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1 -Path "D:\scripts" -ScriptType PowerShell
    Analyse uniquement les scripts PowerShell dans le dossier D:\scripts.

<#
.SYNOPSIS
    Analyse la conformitÃ© des scripts aux standards de codage dÃ©finis.
.DESCRIPTION
    Ce script analyse les scripts PowerShell, Python, Batch et Shell pour vÃ©rifier
    leur conformitÃ© aux standards de codage dÃ©finis dans CodingStandards.md.
    Il gÃ©nÃ¨re un rapport dÃ©taillÃ© des problÃ¨mes trouvÃ©s.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par dÃ©faut: scripts\manager\data\compliance_report.json
.PARAMETER ScriptType
    Type de script Ã  analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1
    Analyse tous les scripts dans le dossier scripts et gÃ©nÃ¨re un rapport.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1 -Path "D:\scripts" -ScriptType PowerShell
    Analyse uniquement les scripts PowerShell dans le dossier D:\scripts.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\manager\data\compliance_report.json",
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
    $LogFile = "scripts\manager\data\compliance_check.log"
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
                if ($null -ne $Matches -and $Matches.Count -gt 0) {
                    $HeaderContent = $Matches[0]
                } else {
                    $HeaderContent = ""
                }

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

                if (-not ($HeaderContent -match "\.EXAMPLE")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas de section EXAMPLE"
                        Severity = "Low"
                    }
                }
            }
        }
        "Python" {
            # VÃ©rifier la prÃ©sence d'un projet/documentationtring
            if (-not ($Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de projet/documentationtring d'en-tÃªte"
                    Severity = "High"
                }
            } else {
                # VÃ©rifier les Ã©lÃ©ments requis dans l'en-tÃªte
                $null = $Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''"
                if ($null -ne $Matches -and $Matches.Count -gt 0) {
                    $HeaderContent = $Matches[0]
                } else {
                    $HeaderContent = ""
                }

                if (-not ($HeaderContent -match "Nom du script" -or $HeaderContent -match "Script name")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas le nom du script"
                        Severity = "Medium"
                    }
                }

                if (-not ($HeaderContent -match "Description")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas de description"
                        Severity = "Medium"
                    }
                }

                if (-not ($HeaderContent -match "Auteur" -or $HeaderContent -match "Author")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tÃªte ne contient pas d'auteur"
                        Severity = "Low"
                    }
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

            # VÃ©rifier la prÃ©sence de commentaires d'en-tÃªte
            if (-not ($Content -match "#[-]+\n#([\s\S]*?)#[-]+")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tÃªte"
                    Severity = "Medium"
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
            # VÃ©rifier l'utilisation de verbes approuvÃ©s
            $Functions = [regex]::Matches($Content, "function\s+([A-Za-z0-9\-]+)")
            foreach ($Function in $Functions) {
                $FunctionName = $Function.Groups[1].Value
                if ($FunctionName -match "^([A-Za-z]+)-") {
                    $Verb = $Matches[1]
                    $ApprovedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
                    if ($ApprovedVerbs -notcontains $Verb) {
                        $Issues += [PSCustomObject]@{
                            Rule = "ApprovedVerb"
                            Description = "La fonction '$FunctionName' utilise un verbe non approuvÃ©: '$Verb'"
                            Severity = "Medium"
                        }
                    }
                }
            }

            # VÃ©rifier les comparaisons avec $null
            $NullComparisons = [regex]::Matches($Content, "(\`$[A-Za-z0-9_]+)\s+-eq\s+\`$null")
            foreach ($Comparison in $NullComparisons) {
                $Issues += [PSCustomObject]@{
                    Rule = "NullComparison"
                    Description = "Comparaison avec `$null incorrecte: '$($Comparison.Value)'. Utilisez plutÃ´t: `$null -eq $($Comparison.Groups[1].Value)"
                    Severity = "Medium"
                }
            }

            # VÃ©rifier l'utilisation de Join-Path pour les chemins
            $PathConcatenations = [regex]::Matches($Content, "\`$[A-Za-z0-9_]+\s*\+\s*['""]\\")
            foreach ($Concatenation in $PathConcatenations) {
                $Issues += [PSCustomObject]@{
                    Rule = "PathConcatenation"
                    Description = "ConcatÃ©nation de chemin dÃ©tectÃ©e: '$($Concatenation.Value)'. Utilisez plutÃ´t Join-Path"
                    Severity = "Low"
                }
            }

            # VÃ©rifier l'utilisation de ${VAR} au lieu de $VAR
            # SimplifiÃ© pour Ã©viter les problÃ¨mes d'expression rÃ©guliÃ¨re
            if ($Content -match '\$[A-Za-z]') {
                $Issues += [PSCustomObject]@{
                    Rule = "VarReference"
                    Description = "Certaines rÃ©fÃ©rences de variables pourraient ne pas Ãªtre protÃ©gÃ©es. Utilisez `${VAR} au lieu de `$VAR."
                    Severity = "Low"
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

            # VÃ©rifier l'organisation des imports
            $ImportLines = $ContentLines | Where-Object { $_ -match "^import\s+" -or $_ -match "^from\s+" }
            $LastImportLine = -1
            foreach ($Line in $ImportLines) {
                $LineNumber = [array]::IndexOf($ContentLines, $Line) + 1
                if ($LastImportLine -ne -1 -and $LineNumber -ne $LastImportLine + 1 -and $ContentLines[$LineNumber - 2] -ne "") {
                    $Issues += [PSCustomObject]@{
                        Rule = "ImportOrganization"
                        Description = "Les imports ne sont pas regroupÃ©s ensemble"
                        Severity = "Low"
                        LineNumber = $LineNumber
                    }
                }
                $LastImportLine = $LineNumber
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

            # VÃ©rifier l'utilisation de setlocal
            if (-not ($Content -match "setlocal")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Setlocal"
                    Description = "Le script n'utilise pas 'setlocal' pour isoler les variables"
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
function Start-ComplianceCheck {
    param (
        [string]$Path,
        [string]$OutputPath,
        [string]$ScriptType,
        [switch]$ShowDetails
    )

    Write-Log "DÃ©marrage de l'analyse de conformitÃ© des scripts..." -Level "TITLE"
    Write-Log "Dossier des scripts: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Fichier de sortie: $OutputPath" -Level "INFO"

    # VÃ©rifier si le dossier des scripts existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le dossier des scripts n'existe pas: $Path" -Level "ERROR"
        return
    }

    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
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

        if ($ShowDetails) {
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

            if ($ShowDetails -and $ScriptResult.IssueCount -gt 0) {
                Write-Log "  ProblÃ¨mes trouvÃ©s: $($ScriptResult.IssueCount)" -Level "WARNING"
                foreach ($Issue in $ScriptResult.Issues) {
                    $SeverityColor = switch ($Issue.Severity) {
                        "High" { "Red" }
                        "Medium" { "Yellow" }
                        "Low" { "White" }
                    }
                    Write-Host "    [$($Issue.Severity)] $($Issue.Rule): $($Issue.Description)" -ForegroundColor $SeverityColor
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
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© haute: $($Results.HighSeverityCount)" -Level "WARNING"
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© moyenne: $($Results.MediumSeverityCount)" -Level "WARNING"
    Write-Log "  ProblÃ¨mes de sÃ©vÃ©ritÃ© basse: $($Results.LowSeverityCount)" -Level "INFO"
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"

    return $Results
}

# ExÃ©cuter la fonction principale
Start-ComplianceCheck -Path $Path -OutputPath $OutputPath -ScriptType $ScriptType -ShowDetails:$ShowDetails

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
