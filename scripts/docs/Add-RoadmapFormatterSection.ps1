# Add-RoadmapFormatterSection.ps1
# Script pour ajouter la section Roadmap Formatter à la roadmap

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Chemin de la roadmap
$RoadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap_perso.md"

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Diviser le contenu en lignes
$RoadmapLines = $RoadmapContent -split "`r?`n"

# Trouver l'index de la section 2.b
$Section2bIndex = -1
for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## 2\.b") {
        $Section2bIndex = $i
        break
    }
}

if ($Section2bIndex -eq -1) {
    Write-Error "Section 2.b non trouvée dans la roadmap"
    exit 1
}

# Trouver l'index de la section 3
$Section3Index = -1
for ($i = $Section2bIndex + 1; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## 3") {
        $Section3Index = $i
        break
    }
}

if ($Section3Index -eq -1) {
    Write-Error "Section 3 non trouvée dans la roadmap"
    exit 1
}

# Créer le contenu de la nouvelle section
$NewSectionContent = @"
## 2.c Outil de formatage de texte pour la roadmap
**Complexite**: Moyenne
**Temps estime**: 2-3 jours
**Progression**: 100% - *Termine le $(Get-Date -Format "dd/MM/yyyy")*

- [x] Analyser les besoins pour le reformatage de texte en format roadmap - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Identifier les différents formats de texte à prendre en charge
  - [x] Définir les règles de conversion en format roadmap
  - [x] Déterminer les options de personnalisation nécessaires
- [x] Créer un script PowerShell pour traiter et reformater le texte - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Développer la fonction de détection du niveau d'indentation
  - [x] Implémenter la fonction de formatage des lignes
  - [x] Créer la fonction d'insertion dans la roadmap
  - [x] Ajouter des options de personnalisation (titre, complexité, temps estimé)
- [x] Créer un script Python pour traiter et reformater le texte - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Développer la fonction de détection du niveau d'indentation
  - [x] Implémenter la fonction de formatage des lignes
  - [x] Créer la fonction d'insertion dans la roadmap
  - [x] Ajouter des options de personnalisation (titre, complexité, temps estimé)
- [x] Créer une interface utilisateur simple pour faciliter l'utilisation - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Développer un menu interactif
  - [x] Ajouter des options pour formater du texte
  - [x] Ajouter des options pour ajouter une section à la roadmap
  - [x] Ajouter des options pour insérer une section entre deux sections existantes
- [x] Tester la fonctionnalité avec différents formats de texte - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Tester avec des listes à puces
  - [x] Tester avec des listes numérotées
  - [x] Tester avec du texte indenté
  - [x] Tester avec des titres et sous-titres

"@

# Insérer la nouvelle section entre les sections 2.b et 3
$NewRoadmapLines = $RoadmapLines[0..($Section3Index - 1)]
$NewRoadmapLines += ""
$NewRoadmapLines += $NewSectionContent -split "`r?`n"
$NewRoadmapLines += $RoadmapLines[$Section3Index..($RoadmapLines.Count - 1)]

# Mettre à jour la date de dernière mise à jour
$NewRoadmapContent = $NewRoadmapLines -join "`n"
$NewRoadmapContent = $NewRoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $NewRoadmapContent

Write-Host "✅ Section 'Outil de formatage de texte pour la roadmap' ajoutée à la roadmap avec succès." -ForegroundColor Green
