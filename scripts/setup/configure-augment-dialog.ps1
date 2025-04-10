# Script pour configurer Augment afin de supprimer la boîte de dialogue "Keep All"
# Ce script modifie les paramètres VS Code pour Augment

Write-Host "=== Configuration d'Augment pour supprimer la boîte de dialogue 'Keep All' ===" -ForegroundColor Cyan

# Chemin vers le fichier settings.json de VS Code
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Vérifier si le fichier existe
if (-not (Test-Path $settingsPath)) {
    Write-Host "❌ Le fichier settings.json n'existe pas à l'emplacement : $settingsPath" -ForegroundColor Red
    Write-Host "Création d'un nouveau fichier settings.json..." -ForegroundColor Yellow

    # Créer le répertoire parent si nécessaire
    $settingsDir = Split-Path -Parent $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # Créer un fichier settings.json vide avec une structure de base
    $baseSettings = @{} | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $baseSettings
    Write-Host "✅ Nouveau fichier settings.json créé" -ForegroundColor Green
}

# Lire le fichier settings.json existant
try {
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    
    # Convertir en PSCustomObject si ce n'est pas déjà le cas
    if ($null -eq $settings) {
        $settings = [PSCustomObject]@{}
    }
} catch {
    Write-Host "❌ Erreur lors de la lecture du fichier settings.json : $_" -ForegroundColor Red
    Write-Host "Création d'un nouvel objet de paramètres..." -ForegroundColor Yellow
    $settings = [PSCustomObject]@{}
}

# Ajouter ou mettre à jour les paramètres Augment
$augmentParams = @{
    "augment.chat.autoConfirmLargeMessages" = $true
    "augment.chat.maxMessageSizeKB" = 100
    "augment.ui.suppressDialogs" = @("keepAll", "largeOutput")
    "augment.ui.autoConfirmKeepAll" = $true
    "augment.ui.autoConfirmLargeOutput" = $true
}

# Ajouter ou mettre à jour chaque paramètre
foreach ($param in $augmentParams.Keys) {
    # Vérifier si la propriété existe
    if (Get-Member -InputObject $settings -Name $param -MemberType Properties) {
        # Mettre à jour la propriété existante
        $settings.$param = $augmentParams[$param]
        Write-Host "✅ Paramètre mis à jour : $param" -ForegroundColor Green
    } else {
        # Ajouter la nouvelle propriété
        $settings | Add-Member -NotePropertyName $param -NotePropertyValue $augmentParams[$param]
        Write-Host "✅ Paramètre ajouté : $param" -ForegroundColor Green
    }
}

# Sauvegarder les modifications
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "✅ Fichier settings.json mis à jour avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

# Créer le fichier de directives pour Augment Chat
$guidelinesDir = ".\.augment"
$guidelinesPath = "$guidelinesDir\chat_guidelines.md"

# Créer le répertoire .augment s'il n'existe pas
if (-not (Test-Path $guidelinesDir)) {
    New-Item -ItemType Directory -Path $guidelinesDir -Force | Out-Null
    Write-Host "✅ Répertoire .augment créé" -ForegroundColor Green
}

# Contenu des directives
$guidelinesContent = @"
# Directives pour Augment Chat

## Comportement général
- Sois concis et précis dans tes réponses
- Évite les longues explications inutiles
- Concentre-toi sur la résolution du problème posé
- Utilise des exemples de code courts et pertinents
- Divise les réponses complexes en plusieurs messages plus courts

## Gestion des boîtes de dialogue
- Valide automatiquement la boîte de dialogue "Keep All" lorsqu'elle apparaît
- Évite de générer des réponses trop longues qui déclencheraient cette boîte de dialogue
- Limite les extraits de code à 50 lignes maximum par bloc
- Utilise des liens vers les fichiers plutôt que d'inclure leur contenu complet

## Format des réponses
- Utilise des listes à puces pour les étapes ou points importants
- Mets en évidence les informations critiques en **gras**
- Utilise des blocs de code avec la syntaxe appropriée
- Inclus des en-têtes clairs pour structurer tes réponses

## Limitations techniques
- Évite de dépasser 8000-10000 caractères par message
- Divise les modifications de code en plusieurs appels si nécessaire
- Préfère l'insertion de code plutôt que le remplacement de grands blocs
- Utilise des références relatives aux fichiers plutôt que des chemins absolus

## Préférences linguistiques
- Réponds en français sauf si explicitement demandé autrement
- Utilise un ton professionnel mais convivial
- Évite le jargon technique excessif
- Explique les termes techniques si nécessaire

## Gestion des erreurs
- Fournis des messages d'erreur clairs et des solutions possibles
- Suggère des alternatives en cas d'échec d'une approche
- Documente les erreurs rencontrées pour référence future
- Propose des étapes de débogage progressives

## Sécurité
- Ne partage jamais de tokens, clés API ou informations sensibles
- Vérifie les permissions avant d'exécuter des commandes potentiellement dangereuses
- Demande confirmation avant d'effectuer des actions destructives
- Suggère des pratiques sécurisées lorsque pertinent
"@

# Écrire le fichier de directives
Set-Content -Path $guidelinesPath -Value $guidelinesContent
Write-Host "✅ Fichier de directives créé : $guidelinesPath" -ForegroundColor Green

# Ajouter le chemin des directives aux paramètres VS Code
if (Get-Member -InputObject $settings -Name "augment.chat.guidelinesPath" -MemberType Properties) {
    $settings."augment.chat.guidelinesPath" = $guidelinesPath
    Write-Host "✅ Paramètre mis à jour : augment.chat.guidelinesPath" -ForegroundColor Green
} else {
    $settings | Add-Member -NotePropertyName "augment.chat.guidelinesPath" -NotePropertyValue $guidelinesPath
    Write-Host "✅ Paramètre ajouté : augment.chat.guidelinesPath" -ForegroundColor Green
}

# Sauvegarder les modifications finales
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "✅ Fichier settings.json mis à jour avec le chemin des directives" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuration terminée ===" -ForegroundColor Cyan
Write-Host "Augment a été configuré pour supprimer automatiquement la boîte de dialogue 'Keep All'."
Write-Host "Redémarrez VS Code pour appliquer les changements."
Write-Host "`nPour redémarrer VS Code, vous pouvez exécuter :"
Write-Host ".\scripts\cmd\batch\restart_vscode.cmd" -ForegroundColor Yellow
