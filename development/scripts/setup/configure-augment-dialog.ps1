# Script pour configurer Augment afin de supprimer la boÃƒÂ®te de dialogue "Keep All"
# Ce script modifie les paramÃƒÂ¨tres VS Code pour Augment

Write-Host "=== Configuration d'Augment pour supprimer la boÃƒÂ®te de dialogue 'Keep All' ===" -ForegroundColor Cyan

# Chemin vers le fichier settings.json de VS Code
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# VÃƒÂ©rifier si le fichier existe
if (-not (Test-Path $settingsPath)) {
    Write-Host "Ã¢ÂÅ’ Le fichier settings.json n'existe pas ÃƒÂ  l'emplacement : $settingsPath" -ForegroundColor Red
    Write-Host "CrÃƒÂ©ation d'un nouveau fichier settings.json..." -ForegroundColor Yellow

    # CrÃƒÂ©er le rÃƒÂ©pertoire parent si nÃƒÂ©cessaire
    $settingsDir = Split-Path -Parent $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # CrÃƒÂ©er un fichier settings.json vide avec une structure de base
    $baseSettings = @{} | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $baseSettings
    Write-Host "Ã¢Å“â€¦ Nouveau fichier settings.json crÃƒÂ©ÃƒÂ©" -ForegroundColor Green
}

# Lire le fichier settings.json existant
try {
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    
    # Convertir en PSCustomObject si ce n'est pas dÃƒÂ©jÃƒÂ  le cas
    if ($null -eq $settings) {
        $settings = [PSCustomObject]@{}
    }
} catch {
    Write-Host "Ã¢ÂÅ’ Erreur lors de la lecture du fichier settings.json : $_" -ForegroundColor Red
    Write-Host "CrÃƒÂ©ation d'un nouvel objet de paramÃƒÂ¨tres..." -ForegroundColor Yellow
    $settings = [PSCustomObject]@{}
}

# Ajouter ou mettre ÃƒÂ  jour les paramÃƒÂ¨tres Augment
$augmentParams = @{
    "augment.chat.autoConfirmLargeMessages" = $true
    "augment.chat.maxMessageSizeKB" = 100
    "augment.ui.suppressDialogs" = @("keepAll", "largeOutput")
    "augment.ui.autoConfirmKeepAll" = $true
    "augment.ui.autoConfirmLargeOutput" = $true
}

# Ajouter ou mettre ÃƒÂ  jour chaque paramÃƒÂ¨tre
foreach ($param in $augmentParams.Keys) {
    # VÃƒÂ©rifier si la propriÃƒÂ©tÃƒÂ© existe
    if (Get-Member -InputObject $settings -Name $param -MemberType Properties) {
        # Mettre ÃƒÂ  jour la propriÃƒÂ©tÃƒÂ© existante
        $settings.$param = $augmentParams[$param]
        Write-Host "Ã¢Å“â€¦ ParamÃƒÂ¨tre mis ÃƒÂ  jour : $param" -ForegroundColor Green
    } else {
        # Ajouter la nouvelle propriÃƒÂ©tÃƒÂ©
        $settings | Add-Member -NotePropertyName $param -NotePropertyValue $augmentParams[$param]
        Write-Host "Ã¢Å“â€¦ ParamÃƒÂ¨tre ajoutÃƒÂ© : $param" -ForegroundColor Green
    }
}

# Sauvegarder les modifications
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "Ã¢Å“â€¦ Fichier settings.json mis ÃƒÂ  jour avec succÃƒÂ¨s" -ForegroundColor Green
} catch {
    Write-Host "Ã¢ÂÅ’ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

# CrÃƒÂ©er le fichier de directives pour Augment Chat
$guidelinesDir = ".\.augment"
$guidelinesPath = "$guidelinesDir\chat_guidelines.md"

# CrÃƒÂ©er le rÃƒÂ©pertoire .augment s'il n'existe pas
if (-not (Test-Path $guidelinesDir)) {
    New-Item -ItemType Directory -Path $guidelinesDir -Force | Out-Null
    Write-Host "Ã¢Å“â€¦ RÃƒÂ©pertoire .augment crÃƒÂ©ÃƒÂ©" -ForegroundColor Green
}

# Contenu des directives
$guidelinesContent = @"
# Directives pour Augment Chat

## Comportement gÃƒÂ©nÃƒÂ©ral
- Sois concis et prÃƒÂ©cis dans tes rÃƒÂ©ponses
- Ãƒâ€°vite les longues explications inutiles
- Concentre-toi sur la rÃƒÂ©solution du problÃƒÂ¨me posÃƒÂ©
- Utilise des exemples de code courts et pertinents
- Divise les rÃƒÂ©ponses complexes en plusieurs messages plus courts

## Gestion des boÃƒÂ®tes de dialogue
- Valide automatiquement la boÃƒÂ®te de dialogue "Keep All" lorsqu'elle apparaÃƒÂ®t
- Ãƒâ€°vite de gÃƒÂ©nÃƒÂ©rer des rÃƒÂ©ponses trop longues qui dÃƒÂ©clencheraient cette boÃƒÂ®te de dialogue
- Limite les extraits de code ÃƒÂ  50 lignes maximum par bloc
- Utilise des liens vers les fichiers plutÃƒÂ´t que d'inclure leur contenu complet

## Format des rÃƒÂ©ponses
- Utilise des listes ÃƒÂ  puces pour les ÃƒÂ©tapes ou points importants
- Mets en ÃƒÂ©vidence les informations critiques en **gras**
- Utilise des blocs de code avec la syntaxe appropriÃƒÂ©e
- Inclus des en-tÃƒÂªtes clairs pour structurer tes rÃƒÂ©ponses

## Limitations techniques
- Ãƒâ€°vite de dÃƒÂ©passer 8000-10000 caractÃƒÂ¨res par message
- Divise les modifications de code en plusieurs appels si nÃƒÂ©cessaire
- PrÃƒÂ©fÃƒÂ¨re l'insertion de code plutÃƒÂ´t que le remplacement de grands blocs
- Utilise des rÃƒÂ©fÃƒÂ©rences relatives aux fichiers plutÃƒÂ´t que des chemins absolus

## PrÃƒÂ©fÃƒÂ©rences linguistiques
- RÃƒÂ©ponds en franÃƒÂ§ais sauf si explicitement demandÃƒÂ© autrement
- Utilise un ton professionnel mais convivial
- Ãƒâ€°vite le jargon technique excessif
- Explique les termes techniques si nÃƒÂ©cessaire

## Gestion des erreurs
- Fournis des messages d'erreur clairs et des solutions possibles
- SuggÃƒÂ¨re des alternatives en cas d'ÃƒÂ©chec d'une approche
- Documente les erreurs rencontrÃƒÂ©es pour rÃƒÂ©fÃƒÂ©rence future
- Propose des ÃƒÂ©tapes de dÃƒÂ©bogage progressives

## SÃƒÂ©curitÃƒÂ©
- Ne partage jamais de tokens, clÃƒÂ©s API ou informations sensibles
- VÃƒÂ©rifie les permissions avant d'exÃƒÂ©cuter des commandes potentiellement dangereuses
- Demande confirmation avant d'effectuer des actions destructives
- SuggÃƒÂ¨re des pratiques sÃƒÂ©curisÃƒÂ©es lorsque pertinent
"@

# Ãƒâ€°crire le fichier de directives
Set-Content -Path $guidelinesPath -Value $guidelinesContent
Write-Host "Ã¢Å“â€¦ Fichier de directives crÃƒÂ©ÃƒÂ© : $guidelinesPath" -ForegroundColor Green

# Ajouter le chemin des directives aux paramÃƒÂ¨tres VS Code
if (Get-Member -InputObject $settings -Name "augment.chat.guidelinesPath" -MemberType Properties) {
    $settings."augment.chat.guidelinesPath" = $guidelinesPath
    Write-Host "Ã¢Å“â€¦ ParamÃƒÂ¨tre mis ÃƒÂ  jour : augment.chat.guidelinesPath" -ForegroundColor Green
} else {
    $settings | Add-Member -NotePropertyName "augment.chat.guidelinesPath" -NotePropertyValue $guidelinesPath
    Write-Host "Ã¢Å“â€¦ ParamÃƒÂ¨tre ajoutÃƒÂ© : augment.chat.guidelinesPath" -ForegroundColor Green
}

# Sauvegarder les modifications finales
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "Ã¢Å“â€¦ Fichier settings.json mis ÃƒÂ  jour avec le chemin des directives" -ForegroundColor Green
} catch {
    Write-Host "Ã¢ÂÅ’ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuration terminÃƒÂ©e ===" -ForegroundColor Cyan
Write-Host "Augment a ÃƒÂ©tÃƒÂ© configurÃƒÂ© pour supprimer automatiquement la boÃƒÂ®te de dialogue 'Keep All'."
Write-Host "RedÃƒÂ©marrez VS Code pour appliquer les changements."
Write-Host "`nPour redÃƒÂ©marrer VS Code, vous pouvez exÃƒÂ©cuter :"
Write-Host ".\development\scripts\cmd\batch\restart_vscode.cmd" -ForegroundColor Yellow
