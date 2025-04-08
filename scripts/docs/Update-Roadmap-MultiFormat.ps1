# Update-Roadmap-MultiFormat.ps1
# Script pour mettre a jour la roadmap avec les nouvelles fonctionnalites de support multi-format

# Chemin de la roadmap
$RoadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap_perso.md"

# Verifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Diviser le contenu en lignes
$RoadmapLines = $RoadmapContent -split "`r?`n"

# Trouver l'index de la section 2.c
$Section2cIndex = -1
for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## 2\.c") {
        $Section2cIndex = $i
        break
    }
}

if ($Section2cIndex -eq -1) {
    Write-Error "Section 2.c non trouvee dans la roadmap"
    exit 1
}

# Trouver la fin de la section 2.c
$EndOfSection2cIndex = -1
for ($i = $Section2cIndex + 1; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## ") {
        $EndOfSection2cIndex = $i - 1
        break
    }
}

if ($EndOfSection2cIndex -eq -1) {
    $EndOfSection2cIndex = $RoadmapLines.Count - 1
}

# Ajouter les nouvelles taches a la section 2.c
$NewTasks = @"
- [x] Ajouter le support pour d'autres formats de texte - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Creer un module de conversion entre differents formats
  - [x] Implementer la conversion depuis Markdown
  - [x] Implementer la conversion depuis CSV
  - [x] Implementer la conversion depuis JSON
  - [x] Implementer la conversion depuis YAML
  - [x] Implementer la conversion vers Markdown
  - [x] Implementer la conversion vers CSV
  - [x] Implementer la conversion vers JSON
  - [x] Implementer la conversion vers YAML
- [x] Ameliorer l'interface utilisateur pour le support multi-format - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Creer une interface pour la conversion de fichiers
  - [x] Creer une interface pour la conversion de texte
  - [x] Ajouter des options pour les formats d'entree et de sortie
  - [x] Ajouter des options pour les metadonnees et la hierarchie
- [x] Creer des exemples pour les differents formats - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Creer un exemple Markdown
  - [x] Creer un exemple CSV
  - [x] Creer un exemple JSON
  - [x] Creer un exemple YAML
- [x] Tester les conversions entre les differents formats - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Tester la conversion depuis Markdown
  - [x] Tester la conversion depuis CSV
  - [x] Tester la conversion depuis JSON
  - [x] Tester la conversion depuis YAML
  - [x] Tester la conversion vers Markdown
  - [x] Tester la conversion vers CSV
  - [x] Tester la conversion vers JSON
  - [x] Tester la conversion vers YAML
"@

# Inserer les nouvelles taches avant la fin de la section 2.c
$NewRoadmapLines = $RoadmapLines[0..$EndOfSection2cIndex]
$NewRoadmapLines += $NewTasks -split "`r?`n"
$NewRoadmapLines += $RoadmapLines[($EndOfSection2cIndex + 1)..($RoadmapLines.Count - 1)]

# Mettre a jour la date de derniere mise a jour
$NewRoadmapContent = $NewRoadmapLines -join "`n"
$NewRoadmapContent = $NewRoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Ecrire le contenu mis a jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $NewRoadmapContent

Write-Host "La roadmap a ete mise a jour avec les nouvelles fonctionnalites de support multi-format" -ForegroundColor Green
