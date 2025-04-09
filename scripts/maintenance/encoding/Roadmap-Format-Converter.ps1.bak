# Roadmap-Format-Converter.ps1
# Interface utilisateur pour convertir entre differents formats de roadmap

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  ROADMAP FORMAT CONVERTER                    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] " -ForegroundColor Yellow -NoNewline; Write-Host "Convertir un fichier"
    Write-Host "  [2] " -ForegroundColor Yellow -NoNewline; Write-Host "Convertir du texte"
    Write-Host "  [3] " -ForegroundColor Yellow -NoNewline; Write-Host "Aide et exemples"
    Write-Host "  [4] " -ForegroundColor Yellow -NoNewline; Write-Host "Quitter"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║  Formats supportes: Markdown, CSV, JSON, YAML                ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "Votre choix"
    
    switch ($choice) {
        "1" { Convert-File }
        "2" { Convert-Text }
        "3" { Show-Help }
        "4" { exit }
        default { Show-MainMenu }
    }
}

# Fonction pour afficher l'aide et les exemples
function Show-Help {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  AIDE ET EXEMPLES                            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "FORMATS SUPPORTES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Markdown:" -ForegroundColor Green
    Write-Host "   # Titre du projet"
    Write-Host "   ## Phase 1: Analyse"
    Write-Host "   - Identifier les besoins"
    Write-Host "   - Documenter les cas d'utilisation"
    Write-Host ""
    Write-Host "2. CSV:" -ForegroundColor Green
    Write-Host "   Task,Level,Priority,TimeEstimate"
    Write-Host "   Analyse,0,False,"
    Write-Host "   Identifier les besoins,1,False,2 jours"
    Write-Host "   Documenter les cas d'utilisation,1,True,3 jours"
    Write-Host ""
    Write-Host "3. JSON:" -ForegroundColor Green
    Write-Host "   ["
    Write-Host "     {"
    Write-Host "       \"name\": \"Analyse\","
    Write-Host "       \"isPhase\": true,"
    Write-Host "       \"subtasks\": ["
    Write-Host "         {"
    Write-Host "           \"name\": \"Identifier les besoins\","
    Write-Host "           \"timeEstimate\": \"2 jours\""
    Write-Host "         }"
    Write-Host "       ]"
    Write-Host "     }"
    Write-Host "   ]"
    Write-Host ""
    Write-Host "4. YAML:" -ForegroundColor Green
    Write-Host "   - name: Analyse"
    Write-Host "     isPhase: true"
    Write-Host "     subtasks:"
    Write-Host "       - name: Identifier les besoins"
    Write-Host "         timeEstimate: 2 jours"
    Write-Host ""
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-MainMenu
}

# Fonction pour convertir un fichier
function Convert-File {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  CONVERTIR UN FICHIER                        ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $inputFile = Read-Host "Chemin du fichier d'entree"
    if (-not (Test-Path -Path $inputFile)) {
        Write-Host "Le fichier n'existe pas: $inputFile" -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour continuer"
        Show-MainMenu
        return
    }
    
    Write-Host ""
    Write-Host "Formats d'entree disponibles:" -ForegroundColor Yellow
    Write-Host "  [1] Auto (detection automatique)"
    Write-Host "  [2] Plain (texte brut)"
    Write-Host "  [3] Markdown"
    Write-Host "  [4] CSV"
    Write-Host "  [5] JSON"
    Write-Host "  [6] YAML"
    Write-Host ""
    $inputFormatChoice = Read-Host "Format d'entree"
    
    $inputFormat = "Auto"
    switch ($inputFormatChoice) {
        "1" { $inputFormat = "Auto" }
        "2" { $inputFormat = "Plain" }
        "3" { $inputFormat = "Markdown" }
        "4" { $inputFormat = "CSV" }
        "5" { $inputFormat = "JSON" }
        "6" { $inputFormat = "YAML" }
        default { $inputFormat = "Auto" }
    }
    
    Write-Host ""
    Write-Host "Formats de sortie disponibles:" -ForegroundColor Yellow
    Write-Host "  [1] Roadmap"
    Write-Host "  [2] Markdown"
    Write-Host "  [3] CSV"
    Write-Host "  [4] JSON"
    Write-Host "  [5] YAML"
    Write-Host ""
    $outputFormatChoice = Read-Host "Format de sortie"
    
    $outputFormat = "Roadmap"
    switch ($outputFormatChoice) {
        "1" { $outputFormat = "Roadmap" }
        "2" { $outputFormat = "Markdown" }
        "3" { $outputFormat = "CSV" }
        "4" { $outputFormat = "JSON" }
        "5" { $outputFormat = "YAML" }
        default { $outputFormat = "Roadmap" }
    }
    
    $outputFile = Read-Host "Chemin du fichier de sortie"
    if ([string]::IsNullOrWhiteSpace($outputFile)) {
        $outputFile = "$inputFile.converted"
    }
    
    $sectionTitle = Read-Host "Titre de la section (par defaut: Nouvelle section)"
    if ([string]::IsNullOrWhiteSpace($sectionTitle)) {
        $sectionTitle = "Nouvelle section"
    }
    
    $complexity = Read-Host "Complexite (par defaut: Moyenne)"
    if ([string]::IsNullOrWhiteSpace($complexity)) {
        $complexity = "Moyenne"
    }
    
    $timeEstimate = Read-Host "Temps estime (par defaut: 3-5 jours)"
    if ([string]::IsNullOrWhiteSpace($timeEstimate)) {
        $timeEstimate = "3-5 jours"
    }
    
    Write-Host ""
    Write-Host "Options supplementaires:" -ForegroundColor Yellow
    $includeMetadata = (Read-Host "Inclure les metadonnees? (O/N)") -eq "O"
    $hierarchical = (Read-Host "Format hierarchique pour JSON/YAML? (O/N)") -eq "O"
    $includeCheckboxes = (Read-Host "Inclure les cases a cocher pour Markdown? (O/N)") -eq "O"
    
    # Executer la conversion
    $formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap-Enhanced.ps1"
    
    $params = @{
        InputFile = $inputFile
        OutputFile = $outputFile
        InputFormat = $inputFormat
        OutputFormat = $outputFormat
        SectionTitle = $sectionTitle
        Complexity = $complexity
        TimeEstimate = $timeEstimate
    }
    
    if ($includeMetadata) {
        $params.IncludeMetadata = $true
    }
    
    if ($hierarchical) {
        $params.Hierarchical = $true
    }
    
    if ($includeCheckboxes) {
        $params.IncludeCheckboxes = $true
    }
    
    Write-Host ""
    Write-Host "Conversion en cours..." -ForegroundColor Yellow
    
    & $formatScript @params
    
    Write-Host ""
    Write-Host "Conversion terminee!" -ForegroundColor Green
    Write-Host "Le fichier a ete enregistre: $outputFile" -ForegroundColor Green
    
    Read-Host "Appuyez sur Entree pour continuer"
    Show-MainMenu
}

# Fonction pour convertir du texte
function Convert-Text {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  CONVERTIR DU TEXTE                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Veuillez saisir le texte a convertir (terminez par une ligne vide):" -ForegroundColor Yellow
    
    $lines = @()
    $line = Read-Host
    while (-not [string]::IsNullOrWhiteSpace($line)) {
        $lines += $line
        $line = Read-Host
    }
    
    $text = $lines -join "`n"
    
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "Aucun texte saisi." -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour continuer"
        Show-MainMenu
        return
    }
    
    Write-Host ""
    Write-Host "Formats d'entree disponibles:" -ForegroundColor Yellow
    Write-Host "  [1] Auto (detection automatique)"
    Write-Host "  [2] Plain (texte brut)"
    Write-Host "  [3] Markdown"
    Write-Host "  [4] CSV"
    Write-Host "  [5] JSON"
    Write-Host "  [6] YAML"
    Write-Host ""
    $inputFormatChoice = Read-Host "Format d'entree"
    
    $inputFormat = "Auto"
    switch ($inputFormatChoice) {
        "1" { $inputFormat = "Auto" }
        "2" { $inputFormat = "Plain" }
        "3" { $inputFormat = "Markdown" }
        "4" { $inputFormat = "CSV" }
        "5" { $inputFormat = "JSON" }
        "6" { $inputFormat = "YAML" }
        default { $inputFormat = "Auto" }
    }
    
    Write-Host ""
    Write-Host "Formats de sortie disponibles:" -ForegroundColor Yellow
    Write-Host "  [1] Roadmap"
    Write-Host "  [2] Markdown"
    Write-Host "  [3] CSV"
    Write-Host "  [4] JSON"
    Write-Host "  [5] YAML"
    Write-Host ""
    $outputFormatChoice = Read-Host "Format de sortie"
    
    $outputFormat = "Roadmap"
    switch ($outputFormatChoice) {
        "1" { $outputFormat = "Roadmap" }
        "2" { $outputFormat = "Markdown" }
        "3" { $outputFormat = "CSV" }
        "4" { $outputFormat = "JSON" }
        "5" { $outputFormat = "YAML" }
        default { $outputFormat = "Roadmap" }
    }
    
    $sectionTitle = Read-Host "Titre de la section (par defaut: Nouvelle section)"
    if ([string]::IsNullOrWhiteSpace($sectionTitle)) {
        $sectionTitle = "Nouvelle section"
    }
    
    $complexity = Read-Host "Complexite (par defaut: Moyenne)"
    if ([string]::IsNullOrWhiteSpace($complexity)) {
        $complexity = "Moyenne"
    }
    
    $timeEstimate = Read-Host "Temps estime (par defaut: 3-5 jours)"
    if ([string]::IsNullOrWhiteSpace($timeEstimate)) {
        $timeEstimate = "3-5 jours"
    }
    
    Write-Host ""
    Write-Host "Options supplementaires:" -ForegroundColor Yellow
    $includeMetadata = (Read-Host "Inclure les metadonnees? (O/N)") -eq "O"
    $hierarchical = (Read-Host "Format hierarchique pour JSON/YAML? (O/N)") -eq "O"
    $includeCheckboxes = (Read-Host "Inclure les cases a cocher pour Markdown? (O/N)") -eq "O"
    
    # Executer la conversion
    $formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap-Enhanced.ps1"
    
    $params = @{
        Text = $text
        InputFormat = $inputFormat
        OutputFormat = $outputFormat
        SectionTitle = $sectionTitle
        Complexity = $complexity
        TimeEstimate = $timeEstimate
    }
    
    if ($includeMetadata) {
        $params.IncludeMetadata = $true
    }
    
    if ($hierarchical) {
        $params.Hierarchical = $true
    }
    
    if ($includeCheckboxes) {
        $params.IncludeCheckboxes = $true
    }
    
    Write-Host ""
    Write-Host "Conversion en cours..." -ForegroundColor Yellow
    
    $result = & $formatScript @params
    
    Write-Host ""
    Write-Host "Resultat de la conversion:" -ForegroundColor Green
    Write-Host $result
    
    Write-Host ""
    $saveToFile = Read-Host "Voulez-vous enregistrer le resultat dans un fichier? (O/N)"
    if ($saveToFile -eq "O") {
        $outputFile = Read-Host "Chemin du fichier de sortie"
        if (-not [string]::IsNullOrWhiteSpace($outputFile)) {
            Set-Content -Path $outputFile -Value $result
            Write-Host "Le fichier a ete enregistre: $outputFile" -ForegroundColor Green
        }
    }
    
    Read-Host "Appuyez sur Entree pour continuer"
    Show-MainMenu
}

# Demarrer le programme
Show-MainMenu
