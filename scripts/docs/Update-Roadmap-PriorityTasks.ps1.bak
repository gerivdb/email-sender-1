# Update-Roadmap-PriorityTasks.ps1
# Script pour mettre a jour la roadmap avec des taches prioritaires identifiees lors de l'analyse du thread

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

# Trouver l'index du debut de la roadmap (apres l'en-tete)
$StartIndex = -1
for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## 1\.") {
        $StartIndex = $i
        break
    }
}

if ($StartIndex -eq -1) {
    Write-Error "Structure de la roadmap non reconnue"
    exit 1
}

# Creer une nouvelle section prioritaire
$PrioritySection = @"
## 0. Taches prioritaires (Analyse des erreurs et ameliorations critiques)
**Complexite**: Elevee
**Temps estime**: 7-10 jours
**Progression**: 0% - *Ajoute le $(Get-Date -Format "dd/MM/yyyy")*

- [ ] **Phase 1: Gestion des problemes d'encodage et caracteres speciaux** - *PRIORITAIRE*
  - [ ] Implementer une detection automatique d'encodage avant l'execution des scripts (1 jour)
  - [ ] Creer une fonction de normalisation des caracteres speciaux (1 jour)
  - [ ] Standardiser l'encodage UTF-8 avec BOM pour tous les scripts PowerShell (1 jour)
  - [ ] Developper un systeme de substitution automatique pour les caracteres problematiques (1 jour)

- [ ] **Phase 2: Amelioration de la gestion d'erreurs** - *PRIORITAIRE*
  - [ ] Implementer un framework de gestion d'erreurs standardise (2 jours)
  - [ ] Creer un systeme de journalisation centralise pour les erreurs (1 jour)
  - [ ] Developper des mecanismes de reprise apres erreur (retry logic) (1 jour)
  - [ ] Ajouter des validations d'entree systematiques (1 jour)

- [ ] **Phase 3: Resolution des problemes de compatibilite entre environnements** - *PRIORITAIRE*
  - [ ] Creer un systeme de detection d'environnement automatique (1 jour)
  - [ ] Developper des wrappers pour les commandes specifiques a l'OS (2 jours)
  - [ ] Implementer un verificateur de prerequis avant l'execution des scripts (1 jour)
  - [ ] Standardiser les chemins avec une bibliotheque cross-platform (1 jour)

- [ ] **Phase 4: Amelioration de la gestion des processus** - *PRIORITAIRE*
  - [ ] Developper un gestionnaire de processus robuste (2 jours)
  - [ ] Implementer des timeouts systematiques pour tous les processus (1 jour)
  - [ ] Creer un mecanisme de nettoyage des processus orphelins (1 jour)
  - [ ] Ameliorer la communication inter-processus (2 jours)

- [ ] **Phase 5: Mise en place d'un systeme de gestion des dependances** - *PRIORITAIRE*
  - [ ] Creer un gestionnaire de dependances centralise (2 jours)
  - [ ] Implementer un systeme de verrouillage de versions (1 jour)
  - [ ] Developper un mecanisme de resolution de conflits (2 jours)
  - [ ] Ajouter des tests de compatibilite entre modules (1 jour)

"@

# Inserer la nouvelle section au debut de la roadmap
$NewRoadmapLines = $RoadmapLines[0..($StartIndex - 1)]
$NewRoadmapLines += $PrioritySection -split "`r?`n"
$NewRoadmapLines += $RoadmapLines[$StartIndex..($RoadmapLines.Count - 1)]

# Mettre a jour la date de derniere mise a jour
$NewRoadmapContent = $NewRoadmapLines -join "`n"
$NewRoadmapContent = $NewRoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Ecrire le contenu mis a jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $NewRoadmapContent

Write-Host "La roadmap a ete mise a jour avec les taches prioritaires" -ForegroundColor Green
