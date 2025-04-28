#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les scripts du manager.
.DESCRIPTION
    Ce script analyse les scripts du manager pour en extraire des informations
    structurelles, détecter les problèmes potentiels et évaluer la qualité du code.
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports d'analyse.
.PARAMETER ScriptType
    Type de script à analyser (All, PowerShell, Python, Batch, Shell).
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats de l'analyse.
.EXAMPLE
    .\Analyze-Scripts.ps1 -Path "development\scripts\manager" -OutputPath ".\reports\analysis"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = "development\scripts\manager",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\analysis",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour analyser un script
function Get-ScriptInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Extraire les informations du script
        $info = @{
            Path = $FilePath
            Name = Split-Path -Leaf $FilePath
            Extension = [System.IO.Path]::GetExtension($FilePath)
            SizeBytes = (Get-Item -Path $FilePath).Length
            LineCount = ($content -split "`n").Count
            HasSynopsis = $content -match "\.SYNOPSIS"
            HasDescription = $content -match "\.DESCRIPTION"
            HasExample = $content -match "\.EXAMPLE"
            HasParameter = $content -match "\.PARAMETER"
            HasNotes = $content -match "\.NOTES"
            FunctionCount = ([regex]::Matches($content, "function\s+\w+[-\w]*\s*{")).Count
            ParameterCount = ([regex]::Matches($content, "\[Parameter\(")).Count
            CommentLineCount = ([regex]::Matches($content, "^\s*#")).Count
            EmptyLineCount = ([regex]::Matches($content, "^\s*$")).Count
        }
        
        return $info
    }
    catch {
        Write-Error "Erreur lors de l'analyse du script $FilePath : $_"
        return $null
    }
}

# Fonction pour évaluer la qualité d'un script
function Test-ScriptQuality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ScriptInfo
    )
    
    # Définir les seuils de qualité
    $thresholds = @{
        MinLineCount = 10
        MaxLineCount = 1000
        MinCommentRatio = 0.1
        MaxEmptyLineRatio = 0.3
        RequiredElements = @("HasSynopsis", "HasDescription", "HasExample")
    }
    
    # Calculer les métriques
    $metrics = @{
        CommentRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.CommentLineCount / $ScriptInfo.LineCount } else { 0 }
        EmptyLineRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.EmptyLineCount / $ScriptInfo.LineCount } else { 0 }
        MissingElements = @()
    }
    
    # Vérifier les éléments requis
    foreach ($element in $thresholds.RequiredElements) {
        if (-not $ScriptInfo[$element]) {
            $metrics.MissingElements += $element
        }
    }
    
    # Évaluer la qualité
    $quality = @{
        IsValid = $true
        Issues = @()
    }
    
    if ($ScriptInfo.LineCount -lt $thresholds.MinLineCount) {
        $quality.IsValid = $false
        $quality.Issues += "Le script est trop court (moins de $($thresholds.MinLineCount) lignes)"
    }
    
    if ($ScriptInfo.LineCount -gt $thresholds.MaxLineCount) {
        $quality.IsValid = $false
        $quality.Issues += "Le script est trop long (plus de $($thresholds.MaxLineCount) lignes)"
    }
    
    if ($metrics.CommentRatio -lt $thresholds.MinCommentRatio) {
        $quality.IsValid = $false
        $quality.Issues += "Le ratio de commentaires est trop faible (moins de $($thresholds.MinCommentRatio * 100)%)"
    }
    
    if ($metrics.EmptyLineRatio -gt $thresholds.MaxEmptyLineRatio) {
        $quality.IsValid = $false
        $quality.Issues += "Le ratio de lignes vides est trop élevé (plus de $($thresholds.MaxEmptyLineRatio * 100)%)"
    }
    
    if ($metrics.MissingElements.Count -gt 0) {
        $quality.IsValid = $false
        $quality.Issues += "Éléments manquants : $($metrics.MissingElements -join ', ')"
    }
    
    return $quality
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Récupérer les scripts à analyser
$scriptExtensions = switch ($ScriptType) {
    "PowerShell" { @(".ps1", ".psm1", ".psd1") }
    "Python" { @(".py") }
    "Batch" { @(".cmd", ".bat") }
    "Shell" { @(".sh") }
    default { @(".ps1", ".psm1", ".psd1", ".py", ".cmd", ".bat", ".sh") }
}

$scripts = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $scriptExtensions -contains $_.Extension }

if ($scripts.Count -eq 0) {
    Write-Log "Aucun script trouvé." -Level "WARNING"
    exit 0
}

Write-Log "Analyse de $($scripts.Count) script(s)..." -Level "INFO"

# Analyser les scripts
$analysisResults = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Path = $Path
    TotalScripts = $scripts.Count
    ScriptsByExtension = @{}
    ScriptsByQuality = @{
        Valid = 0
        Invalid = 0
    }
    Scripts = @()
}

# Compter les scripts par extension
foreach ($extension in $scriptExtensions) {
    $count = ($scripts | Where-Object { $_.Extension -eq $extension }).Count
    if ($count -gt 0) {
        $analysisResults.ScriptsByExtension[$extension] = $count
    }
}

# Analyser chaque script
$progress = 0
foreach ($script in $scripts) {
    $progress++
    $percent = [math]::Round(($progress / $scripts.Count) * 100)
    Write-Progress -Activity "Analyse des scripts" -Status "$progress / $($scripts.Count) ($percent%)" -PercentComplete $percent
    
    $scriptInfo = Get-ScriptInfo -FilePath $script.FullName
    if ($scriptInfo) {
        $quality = Test-ScriptQuality -ScriptInfo $scriptInfo
        
        $scriptResult = @{
            Name = $script.Name
            Path = $script.FullName
            Extension = $script.Extension
            SizeBytes = $script.Length
            LineCount = $scriptInfo.LineCount
            FunctionCount = $scriptInfo.FunctionCount
            ParameterCount = $scriptInfo.ParameterCount
            CommentLineCount = $scriptInfo.CommentLineCount
            EmptyLineCount = $scriptInfo.EmptyLineCount
            HasSynopsis = $scriptInfo.HasSynopsis
            HasDescription = $scriptInfo.HasDescription
            HasExample = $scriptInfo.HasExample
            HasParameter = $scriptInfo.HasParameter
            HasNotes = $scriptInfo.HasNotes
            IsValid = $quality.IsValid
            Issues = $quality.Issues
        }
        
        $analysisResults.Scripts += $scriptResult
        
        if ($quality.IsValid) {
            $analysisResults.ScriptsByQuality.Valid++
        }
        else {
            $analysisResults.ScriptsByQuality.Invalid++
        }
    }
}

Write-Progress -Activity "Analyse des scripts" -Completed

# Enregistrer les résultats
$jsonPath = Join-Path -Path $OutputPath -ChildPath "analysis_results.json"
$analysisResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Log "Résultats enregistrés: $jsonPath" -Level "SUCCESS"

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "analysis_results.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse des scripts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .valid { color: green; }
        .invalid { color: red; }
        .summary { margin-bottom: 20px; }
        .summary div { margin-bottom: 5px; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse des scripts</h1>
    <p>Généré le $($analysisResults.GeneratedAt)</p>
    
    <h2>Résumé</h2>
    <div class="summary">
        <div>Nombre total de scripts: $($analysisResults.TotalScripts)</div>
        <div>Scripts valides: <span class="valid">$($analysisResults.ScriptsByQuality.Valid)</span></div>
        <div>Scripts invalides: <span class="invalid">$($analysisResults.ScriptsByQuality.Invalid)</span></div>
    </div>
    
    <h2>Répartition par extension</h2>
    <table>
        <tr>
            <th>Extension</th>
            <th>Nombre</th>
        </tr>
"@
    
    foreach ($extension in $analysisResults.ScriptsByExtension.Keys | Sort-Object) {
        $html += @"
        <tr>
            <td>$extension</td>
            <td>$($analysisResults.ScriptsByExtension[$extension])</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Scripts invalides</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Chemin</th>
            <th>Problèmes</th>
        </tr>
"@
    
    $invalidScripts = $analysisResults.Scripts | Where-Object { -not $_.IsValid }
    foreach ($script in $invalidScripts) {
        $html += @"
        <tr>
            <td>$($script.Name)</td>
            <td>$($script.Path)</td>
            <td>$($script.Issues -join '<br>')</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Détail des scripts</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Extension</th>
            <th>Taille (octets)</th>
            <th>Lignes</th>
            <th>Fonctions</th>
            <th>Paramètres</th>
            <th>Commentaires</th>
            <th>Lignes vides</th>
            <th>Synopsis</th>
            <th>Description</th>
            <th>Exemple</th>
            <th>Paramètre</th>
            <th>Notes</th>
            <th>Validité</th>
        </tr>
"@
    
    foreach ($script in $analysisResults.Scripts | Sort-Object -Property Name) {
        $validityClass = if ($script.IsValid) { "valid" } else { "invalid" }
        $validityText = if ($script.IsValid) { "Valide" } else { "Invalide" }
        
        $html += @"
        <tr>
            <td>$($script.Name)</td>
            <td>$($script.Extension)</td>
            <td>$($script.SizeBytes)</td>
            <td>$($script.LineCount)</td>
            <td>$($script.FunctionCount)</td>
            <td>$($script.ParameterCount)</td>
            <td>$($script.CommentLineCount)</td>
            <td>$($script.EmptyLineCount)</td>
            <td>$($script.HasSynopsis)</td>
            <td>$($script.HasDescription)</td>
            <td>$($script.HasExample)</td>
            <td>$($script.HasParameter)</td>
            <td>$($script.HasNotes)</td>
            <td class="$validityClass">$validityText</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Out-File -FilePath $htmlPath -Encoding utf8
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

# Afficher un résumé
Write-Log "`nRésumé de l'analyse:" -Level "INFO"
Write-Log "  Nombre total de scripts: $($analysisResults.TotalScripts)" -Level "INFO"
Write-Log "  Scripts valides: $($analysisResults.ScriptsByQuality.Valid)" -Level "SUCCESS"
Write-Log "  Scripts invalides: $($analysisResults.ScriptsByQuality.Invalid)" -Level $(if ($analysisResults.ScriptsByQuality.Invalid -eq 0) { "SUCCESS" } else { "WARNING" })

Write-Log "`nRépartition par extension:" -Level "INFO"
foreach ($extension in $analysisResults.ScriptsByExtension.Keys | Sort-Object) {
    Write-Log "  $extension: $($analysisResults.ScriptsByExtension[$extension])" -Level "INFO"
}

if ($analysisResults.ScriptsByQuality.Invalid -gt 0) {
    Write-Log "`nScripts invalides:" -Level "WARNING"
    $invalidScripts = $analysisResults.Scripts | Where-Object { -not $_.IsValid }
    foreach ($script in $invalidScripts) {
        Write-Log "  $($script.Name)" -Level "WARNING"
        foreach ($issue in $script.Issues) {
            Write-Log "    - $issue" -Level "WARNING"
        }
    }
}

Write-Log "`nAnalyse terminée." -Level "SUCCESS"
