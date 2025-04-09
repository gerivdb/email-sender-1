<#
.SYNOPSIS
    Analyse la conformité des scripts aux standards de codage définis.
.DESCRIPTION
    Ce script analyse les scripts PowerShell, Python, Batch et Shell pour vérifier
    leur conformité aux standards de codage définis dans CodingStandards.md.
    Il génère un rapport détaillé des problèmes trouvés.
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par défaut: scripts\manager\data\compliance_report.json
.PARAMETER ScriptType
    Type de script à analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par défaut: All
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1
    Analyse tous les scripts dans le dossier scripts et génère un rapport.
.EXAMPLE
    .\Test-ScriptCompliance-v2.ps1 -Path "D:\scripts" -ScriptType PowerShell
    Analyse uniquement les scripts PowerShell dans le dossier D:\scripts.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\manager\data\compliance_report.json",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    [switch]$ShowDetails
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
                if ($null -ne $Matches -and $Matches.Count -gt 0) {
                    $HeaderContent = $Matches[0]
                } else {
                    $HeaderContent = ""
                }

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

                if (-not ($HeaderContent -match "\.EXAMPLE")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas de section EXAMPLE"
                        Severity = "Low"
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
            } else {
                # Vérifier les éléments requis dans l'en-tête
                $null = $Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''"
                if ($null -ne $Matches -and $Matches.Count -gt 0) {
                    $HeaderContent = $Matches[0]
                } else {
                    $HeaderContent = ""
                }

                if (-not ($HeaderContent -match "Nom du script" -or $HeaderContent -match "Script name")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas le nom du script"
                        Severity = "Medium"
                    }
                }

                if (-not ($HeaderContent -match "Description")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas de description"
                        Severity = "Medium"
                    }
                }

                if (-not ($HeaderContent -match "Auteur" -or $HeaderContent -match "Author")) {
                    $Issues += [PSCustomObject]@{
                        Rule = "Header"
                        Description = "L'en-tête ne contient pas d'auteur"
                        Severity = "Low"
                    }
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

            # Vérifier la présence de commentaires d'en-tête
            if (-not ($Content -match "#[-]+\n#([\s\S]*?)#[-]+")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Le script ne contient pas de bloc de commentaires d'en-tête"
                    Severity = "Medium"
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
            # Vérifier l'utilisation de verbes approuvés
            $Functions = [regex]::Matches($Content, "function\s+([A-Za-z0-9\-]+)")
            foreach ($Function in $Functions) {
                $FunctionName = $Function.Groups[1].Value
                if ($FunctionName -match "^([A-Za-z]+)-") {
                    $Verb = $Matches[1]
                    $ApprovedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
                    if ($ApprovedVerbs -notcontains $Verb) {
                        $Issues += [PSCustomObject]@{
                            Rule = "ApprovedVerb"
                            Description = "La fonction '$FunctionName' utilise un verbe non approuvé: '$Verb'"
                            Severity = "Medium"
                        }
                    }
                }
            }

            # Vérifier les comparaisons avec $null
            $NullComparisons = [regex]::Matches($Content, "(\`$[A-Za-z0-9_]+)\s+-eq\s+\`$null")
            foreach ($Comparison in $NullComparisons) {
                $Issues += [PSCustomObject]@{
                    Rule = "NullComparison"
                    Description = "Comparaison avec `$null incorrecte: '$($Comparison.Value)'. Utilisez plutôt: `$null -eq $($Comparison.Groups[1].Value)"
                    Severity = "Medium"
                }
            }

            # Vérifier l'utilisation de Join-Path pour les chemins
            $PathConcatenations = [regex]::Matches($Content, "\`$[A-Za-z0-9_]+\s*\+\s*['""]\\")
            foreach ($Concatenation in $PathConcatenations) {
                $Issues += [PSCustomObject]@{
                    Rule = "PathConcatenation"
                    Description = "Concaténation de chemin détectée: '$($Concatenation.Value)'. Utilisez plutôt Join-Path"
                    Severity = "Low"
                }
            }

            # Vérifier l'utilisation de ${VAR} au lieu de $VAR
            # Simplifié pour éviter les problèmes d'expression régulière
            if ($Content -match '\$[A-Za-z]') {
                $Issues += [PSCustomObject]@{
                    Rule = "VarReference"
                    Description = "Certaines références de variables pourraient ne pas être protégées. Utilisez `${VAR} au lieu de `$VAR."
                    Severity = "Low"
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

            # Vérifier l'organisation des imports
            $ImportLines = $ContentLines | Where-Object { $_ -match "^import\s+" -or $_ -match "^from\s+" }
            $LastImportLine = -1
            foreach ($Line in $ImportLines) {
                $LineNumber = [array]::IndexOf($ContentLines, $Line) + 1
                if ($LastImportLine -ne -1 -and $LineNumber -ne $LastImportLine + 1 -and $ContentLines[$LineNumber - 2] -ne "") {
                    $Issues += [PSCustomObject]@{
                        Rule = "ImportOrganization"
                        Description = "Les imports ne sont pas regroupés ensemble"
                        Severity = "Low"
                        LineNumber = $LineNumber
                    }
                }
                $LastImportLine = $LineNumber
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

            # Vérifier l'utilisation de setlocal
            if (-not ($Content -match "setlocal")) {
                $Issues += [PSCustomObject]@{
                    Rule = "Setlocal"
                    Description = "Le script n'utilise pas 'setlocal' pour isoler les variables"
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
function Start-ComplianceCheck {
    param (
        [string]$Path,
        [string]$OutputPath,
        [string]$ScriptType,
        [switch]$ShowDetails
    )

    Write-Log "Démarrage de l'analyse de conformité des scripts..." -Level "TITLE"
    Write-Log "Dossier des scripts: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Fichier de sortie: $OutputPath" -Level "INFO"

    # Vérifier si le dossier des scripts existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le dossier des scripts n'existe pas: $Path" -Level "ERROR"
        return
    }

    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "SUCCESS"
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
                Write-Log "  Problèmes trouvés: $($ScriptResult.IssueCount)" -Level "WARNING"
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

    Write-Progress -Activity "Analyse de conformité" -Completed

    # Enregistrer les résultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath

    # Afficher un résumé
    Write-Log "Analyse terminée" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysés: $TotalFiles" -Level "INFO"
    Write-Log "Nombre total de problèmes trouvés: $($Results.TotalIssueCount)" -Level "INFO"
    Write-Log "  Problèmes de sévérité haute: $($Results.HighSeverityCount)" -Level "WARNING"
    Write-Log "  Problèmes de sévérité moyenne: $($Results.MediumSeverityCount)" -Level "WARNING"
    Write-Log "  Problèmes de sévérité basse: $($Results.LowSeverityCount)" -Level "INFO"
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"

    return $Results
}

# Exécuter la fonction principale
Start-ComplianceCheck -Path $Path -OutputPath $OutputPath -ScriptType $ScriptType -ShowDetails:$ShowDetails
