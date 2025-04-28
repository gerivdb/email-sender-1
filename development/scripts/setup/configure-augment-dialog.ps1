# Script pour configurer Augment afin de supprimer la boÃ®te de dialogue "Keep All"
# Ce script modifie les paramÃ¨tres VS Code pour Augment

Write-Host "=== Configuration d'Augment pour supprimer la boÃ®te de dialogue 'Keep All' ===" -ForegroundColor Cyan

# Chemin vers le fichier settings.json de VS Code
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# VÃ©rifier si le fichier existe
if (-not (Test-Path $settingsPath)) {
    Write-Host "âŒ Le fichier settings.json n'existe pas Ã  l'emplacement : $settingsPath" -ForegroundColor Red
    Write-Host "CrÃ©ation d'un nouveau fichier settings.json..." -ForegroundColor Yellow

    # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
    $settingsDir = Split-Path -Parent $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # CrÃ©er un fichier settings.json vide avec une structure de base
    $baseSettings = @{} | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $baseSettings
    Write-Host "âœ… Nouveau fichier settings.json crÃ©Ã©" -ForegroundColor Green
}

# Lire le fichier settings.json existant
try {
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    
    # Convertir en PSCustomObject si ce n'est pas dÃ©jÃ  le cas
    if ($null -eq $settings) {
        $settings = [PSCustomObject]@{}
    }
} catch {
    Write-Host "âŒ Erreur lors de la lecture du fichier settings.json : $_" -ForegroundColor Red
    Write-Host "CrÃ©ation d'un nouvel objet de paramÃ¨tres..." -ForegroundColor Yellow
    $settings = [PSCustomObject]@{}
}

# Ajouter ou mettre Ã  jour les paramÃ¨tres Augment
$augmentParams = @{
    "augment.chat.autoConfirmLargeMessages" = $true
    "augment.chat.maxMessageSizeKB" = 100
    "augment.ui.suppressDialogs" = @("keepAll", "largeOutput")
    "augment.ui.autoConfirmKeepAll" = $true
    "augment.ui.autoConfirmLargeOutput" = $true
}

# Ajouter ou mettre Ã  jour chaque paramÃ¨tre
foreach ($param in $augmentParams.Keys) {
    # VÃ©rifier si la propriÃ©tÃ© existe
    if (Get-Member -InputObject $settings -Name $param -MemberType Properties) {
        # Mettre Ã  jour la propriÃ©tÃ© existante
        $settings.$param = $augmentParams[$param]
        Write-Host "âœ… ParamÃ¨tre mis Ã  jour : $param" -ForegroundColor Green
    } else {
        # Ajouter la nouvelle propriÃ©tÃ©
        $settings | Add-Member -NotePropertyName $param -NotePropertyValue $augmentParams[$param]
        Write-Host "âœ… ParamÃ¨tre ajoutÃ© : $param" -ForegroundColor Green
    }
}

# Sauvegarder les modifications
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "âœ… Fichier settings.json mis Ã  jour avec succÃ¨s" -ForegroundColor Green
} catch {
    Write-Host "âŒ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

# CrÃ©er le fichier de directives pour Augment Chat
$guidelinesDir = ".\.augment"
$guidelinesPath = "$guidelinesDir\chat_guidelines.md"

# CrÃ©er le rÃ©pertoire .augment s'il n'existe pas
if (-not (Test-Path $guidelinesDir)) {
    New-Item -ItemType Directory -Path $guidelinesDir -Force | Out-Null
    Write-Host "âœ… RÃ©pertoire .augment crÃ©Ã©" -ForegroundColor Green
}

# Contenu des directives
$guidelinesContent = @"
# Directives pour Augment Chat

## Comportement gÃ©nÃ©ral
- Sois concis et prÃ©cis dans tes rÃ©ponses
- Ã‰vite les longues explications inutiles
- Concentre-toi sur la rÃ©solution du problÃ¨me posÃ©
- Utilise des exemples de code courts et pertinents
- Divise les rÃ©ponses complexes en plusieurs messages plus courts

## Gestion des boÃ®tes de dialogue
- Valide automatiquement la boÃ®te de dialogue "Keep All" lorsqu'elle apparaÃ®t
- Ã‰vite de gÃ©nÃ©rer des rÃ©ponses trop longues qui dÃ©clencheraient cette boÃ®te de dialogue
- Limite les extraits de code Ã  50 lignes maximum par bloc
- Utilise des liens vers les fichiers plutÃ´t que d'inclure leur contenu complet

## Format des rÃ©ponses
- Utilise des listes Ã  puces pour les Ã©tapes ou points importants
- Mets en Ã©vidence les informations critiques en **gras**
- Utilise des blocs de code avec la syntaxe appropriÃ©e
- Inclus des en-tÃªtes clairs pour structurer tes rÃ©ponses

## Limitations techniques
- Ã‰vite de dÃ©passer 8000-10000 caractÃ¨res par message
- Divise les modifications de code en plusieurs appels si nÃ©cessaire
- PrÃ©fÃ¨re l'insertion de code plutÃ´t que le remplacement de grands blocs
- Utilise des rÃ©fÃ©rences relatives aux fichiers plutÃ´t que des chemins absolus

## PrÃ©fÃ©rences linguistiques
- RÃ©ponds en franÃ§ais sauf si explicitement demandÃ© autrement
- Utilise un ton professionnel mais convivial
- Ã‰vite le jargon technique excessif
- Explique les termes techniques si nÃ©cessaire

## Gestion des erreurs
- Fournis des messages d'erreur clairs et des solutions possibles
- SuggÃ¨re des alternatives en cas d'Ã©chec d'une approche
- Documente les erreurs rencontrÃ©es pour rÃ©fÃ©rence future
- Propose des Ã©tapes de dÃ©bogage progressives

## SÃ©curitÃ©
- Ne partage jamais de tokens, clÃ©s API ou informations sensibles
- VÃ©rifie les permissions avant d'exÃ©cuter des commandes potentiellement dangereuses
- Demande confirmation avant d'effectuer des actions destructives
- SuggÃ¨re des pratiques sÃ©curisÃ©es lorsque pertinent
"@

# Ã‰crire le fichier de directives
Set-Content -Path $guidelinesPath -Value $guidelinesContent
Write-Host "âœ… Fichier de directives crÃ©Ã© : $guidelinesPath" -ForegroundColor Green

# Ajouter le chemin des directives aux paramÃ¨tres VS Code
if (Get-Member -InputObject $settings -Name "augment.chat.guidelinesPath" -MemberType Properties) {
    $settings."augment.chat.guidelinesPath" = $guidelinesPath
    Write-Host "âœ… ParamÃ¨tre mis Ã  jour : augment.chat.guidelinesPath" -ForegroundColor Green
} else {
    $settings | Add-Member -NotePropertyName "augment.chat.guidelinesPath" -NotePropertyValue $guidelinesPath
    Write-Host "âœ… ParamÃ¨tre ajoutÃ© : augment.chat.guidelinesPath" -ForegroundColor Green
}

# Sauvegarder les modifications finales
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "âœ… Fichier settings.json mis Ã  jour avec le chemin des directives" -ForegroundColor Green
} catch {
    Write-Host "âŒ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuration terminÃ©e ===" -ForegroundColor Cyan
Write-Host "Augment a Ã©tÃ© configurÃ© pour supprimer automatiquement la boÃ®te de dialogue 'Keep All'."
Write-Host "RedÃ©marrez VS Code pour appliquer les changements."
Write-Host "`nPour redÃ©marrer VS Code, vous pouvez exÃ©cuter :"
Write-Host ".\development\scripts\cmd\batch\restart_vscode.cmd" -ForegroundColor Yellow
