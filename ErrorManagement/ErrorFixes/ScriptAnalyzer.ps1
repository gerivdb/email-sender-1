<#
.SYNOPSIS
    Analyse les scripts PowerShell pour identifier les problèmes de gestion d'erreurs.
.DESCRIPTION
    Ce script analyse les scripts PowerShell existants pour identifier les problèmes
    de gestion d'erreurs et suggérer des améliorations.
.EXAMPLE
    . .\ScriptAnalyzer.ps1
    Analyze-ScriptErrorHandling -Path "C:\path\to\script.ps1"
#>

function Analyze-ScriptErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    begin {
        # Définir les modèles à rechercher
        $patterns = @{
            MissingTryCatch = @{
                Pattern = '(?<!try\s*{[^}]*?)(?<!\$ErrorActionPreference\s*=\s*[''"]SilentlyContinue[''"]\s*)(New-Item|Remove-Item|Set-Content|Add-Content|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process)'
                Description = "Commande potentiellement risquée sans bloc try/catch"
                Severity = "High"
                Suggestion = "Entourer cette commande d'un bloc try/catch pour gérer les erreurs potentielles."
            }
            ErrorActionPreference = @{
                Pattern = '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]'
                Description = "Définition de ErrorActionPreference à Stop"
                Severity = "Info"
                Suggestion = "Cette configuration est bonne pour la gestion d'erreurs, mais assurez-vous d'avoir des blocs try/catch appropriés."
            }
            MissingErrorVariable = @{
                Pattern = '(?<!-ErrorVariable\s+\w+\s*)(?<!-ev\s+\w+\s*)(New-Item|Remove-Item|Set-Content|Add-Content|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod)'
                Description = "Commande sans paramètre ErrorVariable"
                Severity = "Medium"
                Suggestion = "Ajouter le paramètre -ErrorVariable pour capturer les erreurs spécifiques à cette commande."
            }
            WriteError = @{
                Pattern = 'Write-Error'
                Description = "Utilisation de Write-Error"
                Severity = "Info"
                Suggestion = "Considérer l'utilisation de throw pour les erreurs critiques ou d'un système de journalisation centralisé."
            }
            ThrowStatement = @{
                Pattern = 'throw'
                Description = "Utilisation de throw"
                Severity = "Info"
                Suggestion = "Bon pour signaler des erreurs critiques, mais assurez-vous qu'elles sont capturées à un niveau supérieur."
            }
            TryCatchBlock = @{
                Pattern = 'try\s*{[^}]*?}\s*catch\s*{'
                Description = "Bloc try/catch trouvé"
                Severity = "Info"
                Suggestion = "Vérifier que le bloc catch gère correctement l'erreur (journalisation, nettoyage, etc.)."
            }
            EmptyCatchBlock = @{
                Pattern = 'catch\s*{\s*}'
                Description = "Bloc catch vide"
                Severity = "High"
                Suggestion = "Les blocs catch vides masquent les erreurs sans les gérer. Ajoutez au moins une journalisation."
            }
            FinallyBlock = @{
                Pattern = 'finally\s*{'
                Description = "Bloc finally trouvé"
                Severity = "Info"
                Suggestion = "Bon pour le nettoyage des ressources, indépendamment des erreurs."
            }
            TestPath = @{
                Pattern = 'Test-Path'
                Description = "Vérification d'existence de chemin"
                Severity = "Info"
                Suggestion = "Bonne pratique pour éviter les erreurs lors de l'accès aux fichiers."
            }
            ErrorLog = @{
                Pattern = '(Write-Log|Log-Error|Add-Log)'
                Description = "Journalisation d'erreur potentielle"
                Severity = "Info"
                Suggestion = "Vérifier que les erreurs importantes sont correctement journalisées."
            }
        }
        
        $results = @()
    }
    
    process {
        # Obtenir la liste des fichiers à analyser
        $files = if (Test-Path -Path $Path -PathType Container) {
            Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse:$Recurse
        }
        elseif (Test-Path -Path $Path -PathType Leaf) {
            Get-Item -Path $Path
        }
        else {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }
        
        foreach ($file in $files) {
            Write-Verbose "Analyse du fichier: $($file.FullName)"
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $file.FullName -Raw
            
            # Initialiser les résultats pour ce fichier
            $fileResult = [PSCustomObject]@{
                FilePath = $file.FullName
                FileName = $file.Name
                TotalIssues = 0
                HighSeverityIssues = 0
                MediumSeverityIssues = 0
                InfoIssues = 0
                HasTryCatch = $false
                HasErrorHandling = $false
                Issues = @()
                Content = if ($IncludeContent) { $content } else { $null }
                Recommendations = @()
            }
            
            # Analyser le contenu avec chaque modèle
            foreach ($patternName in $patterns.Keys) {
                $pattern = $patterns[$patternName]
                
                # Rechercher les correspondances
                $matches = [regex]::Matches($content, $pattern.Pattern)
                
                foreach ($match in $matches) {
                    # Trouver le numéro de ligne
                    $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
                    
                    # Extraire la ligne complète
                    $lines = $content.Split("`n")
                    $line = if ($lineNumber -le $lines.Length) { $lines[$lineNumber - 1].Trim() } else { "" }
                    
                    # Ajouter l'issue
                    $issue = [PSCustomObject]@{
                        Pattern = $patternName
                        Description = $pattern.Description
                        Severity = $pattern.Severity
                        LineNumber = $lineNumber
                        Line = $line
                        Suggestion = $pattern.Suggestion
                    }
                    
                    $fileResult.Issues += $issue
                    $fileResult.TotalIssues++
                    
                    # Mettre à jour les compteurs de sévérité
                    switch ($pattern.Severity) {
                        "High" { $fileResult.HighSeverityIssues++ }
                        "Medium" { $fileResult.MediumSeverityIssues++ }
                        "Info" { $fileResult.InfoIssues++ }
                    }
                    
                    # Mettre à jour les indicateurs
                    if ($patternName -eq "TryCatchBlock") {
                        $fileResult.HasTryCatch = $true
                        $fileResult.HasErrorHandling = $true
                    }
                    elseif ($patternName -eq "ErrorActionPreference" -or $patternName -eq "TestPath" -or $patternName -eq "ErrorLog") {
                        $fileResult.HasErrorHandling = $true
                    }
                }
            }
            
            # Générer des recommandations
            if ($fileResult.HighSeverityIssues -gt 0) {
                $fileResult.Recommendations += "Priorité élevée: Corriger les $($fileResult.HighSeverityIssues) problèmes de sévérité élevée."
            }
            
            if (-not $fileResult.HasTryCatch) {
                $fileResult.Recommendations += "Ajouter des blocs try/catch pour les opérations critiques."
            }
            
            if (-not $fileResult.HasErrorHandling) {
                $fileResult.Recommendations += "Implémenter une stratégie de gestion d'erreurs (try/catch, ErrorActionPreference, journalisation)."
            }
            
            if ($fileResult.Issues | Where-Object { $_.Pattern -eq "EmptyCatchBlock" }) {
                $fileResult.Recommendations += "Remplir les blocs catch vides avec au moins une journalisation des erreurs."
            }
            
            if (($fileResult.Issues | Where-Object { $_.Pattern -eq "MissingErrorVariable" }).Count -gt 0) {
                $fileResult.Recommendations += "Ajouter des paramètres -ErrorVariable aux commandes critiques pour une meilleure gestion des erreurs."
            }
            
            $results += $fileResult
        }
    }
    
    end {
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path (Get-Location).Path -ChildPath "ErrorHandlingAnalysisReport.html"
            
            $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de gestion d'erreurs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .high { color: #d9534f; font-weight: bold; }
        .medium { color: #f0ad4e; }
        .info { color: #5bc0de; }
        .summary { margin-bottom: 30px; }
        .file-section { margin-bottom: 40px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
        .recommendations { background-color: #f8f9fa; padding: 10px; border-left: 4px solid #5bc0de; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de gestion d'erreurs</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Fichiers analysés: $($results.Count)</p>
        <p>Problèmes de sévérité élevée: $($results | Measure-Object -Property HighSeverityIssues -Sum | Select-Object -ExpandProperty Sum)</p>
        <p>Problèmes de sévérité moyenne: $($results | Measure-Object -Property MediumSeverityIssues -Sum | Select-Object -ExpandProperty Sum)</p>
        <p>Informations: $($results | Measure-Object -Property InfoIssues -Sum | Select-Object -ExpandProperty Sum)</p>
    </div>
    
    <h2>Détails par fichier</h2>
    
$(foreach ($result in $results) {
@"
    <div class="file-section">
        <h3>$($result.FileName)</h3>
        <p>Chemin: $($result.FilePath)</p>
        <p>Total des problèmes: $($result.TotalIssues)</p>
        
        <h4>Problèmes identifiés</h4>
        <table>
            <tr>
                <th>Ligne</th>
                <th>Sévérité</th>
                <th>Description</th>
                <th>Code</th>
                <th>Suggestion</th>
            </tr>
$(foreach ($issue in $result.Issues) {
    $severityClass = switch ($issue.Severity) {
        "High" { "high" }
        "Medium" { "medium" }
        "Info" { "info" }
        default { "" }
    }
@"
            <tr>
                <td>$($issue.LineNumber)</td>
                <td class="$severityClass">$($issue.Severity)</td>
                <td>$($issue.Description)</td>
                <td><code>$([System.Web.HttpUtility]::HtmlEncode($issue.Line))</code></td>
                <td>$($issue.Suggestion)</td>
            </tr>
"@
})
        </table>
        
        <h4>Recommandations</h4>
        <div class="recommendations">
            <ul>
$(foreach ($recommendation in $result.Recommendations) {
@"
                <li>$recommendation</li>
"@
})
            </ul>
        </div>
    </div>
"@
})
</body>
</html>
"@
            
            Set-Content -Path $reportPath -Value $reportContent
            Write-Host "Rapport généré: $reportPath"
        }
        
        return $results
    }
}

function Add-ErrorHandlingToScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Backup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return $false
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = $Path
    }
    
    # Créer une sauvegarde si demandé
    if ($Backup) {
        $backupPath = "$Path.bak"
        Copy-Item -Path $Path -Destination $backupPath -Force
        Write-Verbose "Sauvegarde créée: $backupPath"
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Path -Raw
    
    # Analyser le script
    $analysis = Analyze-ScriptErrorHandling -Path $Path
    
    if ($analysis.TotalIssues -eq 0) {
        Write-Verbose "Aucun problème de gestion d'erreurs détecté dans le script."
        return $true
    }
    
    # Modifications à apporter
    $modifications = @()
    
    # Ajouter une section de configuration de gestion d'erreurs au début du script
    if (-not ($content -match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]')) {
        $errorConfigSection = @"

# Configuration de la gestion d'erreurs
`$ErrorActionPreference = 'Stop'
`$Error.Clear()

"@
        
        # Trouver l'endroit où insérer la configuration
        $insertPosition = 0
        
        # Chercher après les commentaires initiaux et les déclarations param
        if ($content -match '(?s)^(#[^\n]*\n)+') {
            $insertPosition = $matches[0].Length
        }
        
        if ($content -match '(?s)^(#[^\n]*\n)+\s*param\s*\([^\)]+\)') {
            $insertPosition = $matches[0].Length
        }
        
        $modifications += [PSCustomObject]@{
            Type = "Insert"
            Position = $insertPosition
            Content = $errorConfigSection
            Description = "Ajout de la configuration de gestion d'erreurs"
        }
    }
    
    # Ajouter une fonction de journalisation si demandé
    if ($AddLogging -and -not ($content -match 'function\s+Write-Log')) {
        $loggingFunction = @"

# Fonction de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]`$Level = "INFO",
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFilePath = "`$env:TEMP\$(Split-Path -Path $Path -Leaf).log"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "``[`$timestamp``] [`$Level] `$Message"
    
    # Afficher dans la console
    switch (`$Level) {
        "INFO" { Write-Host `$logEntry -ForegroundColor White }
        "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose `$logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        Add-Content -Path `$LogFilePath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}

"@
        
        # Trouver l'endroit où insérer la fonction de journalisation
        $insertPosition = 0
        
        # Chercher après les commentaires initiaux, les déclarations param et la configuration
        if ($content -match '(?s)^(#[^\n]*\n)+\s*(param\s*\([^\)]+\))?\s*(\$ErrorActionPreference\s*=\s*[\'"]Stop[\'"])?\s*') {
            $insertPosition = $matches[0].Length
        }
        
        $modifications += [PSCustomObject]@{
            Type = "Insert"
            Position = $insertPosition
            Content = $loggingFunction
            Description = "Ajout de la fonction de journalisation"
        }
    }
    
    # Entourer les commandes risquées de blocs try/catch
    $riskyCommands = $analysis.Issues | Where-Object { $_.Pattern -eq "MissingTryCatch" }
    
    foreach ($command in $riskyCommands) {
        # Extraire la ligne complète
        $lines = $content.Split("`n")
        $line = $lines[$command.LineNumber - 1]
        
        # Vérifier si la ligne n'est pas déjà dans un bloc try/catch
        $isInTryCatch = $false
        
        for ($i = $command.LineNumber - 2; $i -ge 0; $i--) {
            if ($lines[$i] -match 'try\s*{') {
                $isInTryCatch = $true
                break
            }
            
            if ($lines[$i] -match '}') {
                break
            }
        }
        
        if (-not $isInTryCatch) {
            $indentation = ""
            if ($line -match '^(\s+)') {
                $indentation = $matches[1]
            }
            
            $tryCatchBlock = @"
${indentation}try {
$line
${indentation}}
${indentation}catch {
${indentation}    $(if ($AddLogging) { "Write-Log -Level ERROR -Message `"Erreur lors de l'exécution de la commande: `$_`"" } else { "Write-Error `"Erreur lors de l'exécution de la commande: `$_`"" })
${indentation}}
"@
            
            $modifications += [PSCustomObject]@{
                Type = "Replace"
                LineNumber = $command.LineNumber
                OldContent = $line
                NewContent = $tryCatchBlock
                Description = "Ajout d'un bloc try/catch autour de la commande risquée"
            }
        }
    }
    
    # Remplir les blocs catch vides
    $emptyCatches = $analysis.Issues | Where-Object { $_.Pattern -eq "EmptyCatchBlock" }
    
    foreach ($emptyCatch in $emptyCatches) {
        # Extraire la ligne complète
        $lines = $content.Split("`n")
        $line = $lines[$emptyCatch.LineNumber - 1]
        
        $indentation = ""
        if ($line -match '^(\s+)') {
            $indentation = $matches[1]
        }
        
        $newCatchBlock = @"
$($line.Substring(0, $line.Length - 1))
${indentation}    $(if ($AddLogging) { "Write-Log -Level ERROR -Message `"Une erreur s'est produite: `$_`"" } else { "Write-Error `"Une erreur s'est produite: `$_`"" })
${indentation}}
"@
        
        $modifications += [PSCustomObject]@{
            Type = "Replace"
            LineNumber = $emptyCatch.LineNumber
            OldContent = $line
            NewContent = $newCatchBlock
            Description = "Remplissage du bloc catch vide"
        }
    }
    
    # Appliquer les modifications si ce n'est pas un test
    if (-not $WhatIf) {
        # Trier les modifications par position/ligne (en ordre décroissant pour éviter les décalages)
        $sortedModifications = $modifications | Sort-Object -Property @{
            Expression = { if ($_.Type -eq "Insert") { $_.Position } else { $_.LineNumber } }
            Descending = $true
        }
        
        # Appliquer les modifications
        $modifiedContent = $content
        
        foreach ($mod in $sortedModifications) {
            if ($mod.Type -eq "Insert") {
                $modifiedContent = $modifiedContent.Substring(0, $mod.Position) + $mod.Content + $modifiedContent.Substring($mod.Position)
            }
            elseif ($mod.Type -eq "Replace") {
                $lines = $modifiedContent.Split("`n")
                $lines[$mod.LineNumber - 1] = $mod.NewContent
                $modifiedContent = $lines -join "`n"
            }
        }
        
        # Écrire le contenu modifié
        Set-Content -Path $OutputPath -Value $modifiedContent
        
        Write-Verbose "Script modifié avec $($modifications.Count) améliorations de gestion d'erreurs."
        return $true
    }
    else {
        # Afficher les modifications prévues
        Write-Host "Modifications prévues pour le script '$Path':"
        
        foreach ($mod in $modifications) {
            Write-Host "- $($mod.Description)"
            
            if ($mod.Type -eq "Insert") {
                Write-Host "  Position: $($mod.Position)"
                Write-Host "  Contenu à insérer:"
                Write-Host $mod.Content
            }
            elseif ($mod.Type -eq "Replace") {
                Write-Host "  Ligne: $($mod.LineNumber)"
                Write-Host "  Ancien contenu:"
                Write-Host $mod.OldContent
                Write-Host "  Nouveau contenu:"
                Write-Host $mod.NewContent
            }
            
            Write-Host ""
        }
        
        return $modifications
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Analyze-ScriptErrorHandling, Add-ErrorHandlingToScript
