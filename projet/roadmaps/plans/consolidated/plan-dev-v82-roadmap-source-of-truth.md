# plan-dev-v82-roadmap-source-of-truth.md

## 🚨 CONSIGNES CRITIQUES DE VÉRIFICATION

### Avant CHAQUE étape

- [ ] **VÉRIFIER la branche actuelle** : `git branch` et `git status`
- [ ] **VÉRIFIER les imports** : cohérence des chemins relatifs/absolus
- [ ] **VÉRIFIER la stack** : `go mod tidy` et `go build ./...`
- [ ] **VÉRIFIER les fichiers requis** : présence de tous les composants
- [ ] **VÉRIFIER la responsabilité** : éviter la duplication de code
- [ ] **TESTER avant commit** : `go test ./...` doit passer à 100%

### À CHAQUE section majeure

- [ ] **COMMITTER sur la bonne branche** : vérifier correspondance
- [ ] **PUSHER immédiatement** : `git push origin [branch-name]`
- [ ] **DOCUMENTER les changements** : mise à jour du README
- [ ] **VALIDER l'intégration** : tests end-to-end

### Responsabilités par branche

- **main** : Code de production stable uniquement
- **dev** : Intégration et tests de l'écosystème unifié  
- **managers** : Développement des managers individuels
- **vectorization-go** : Migration Python→Go des vecteurs
- **consolidation-v57** : Branche dédiée pour ce plan

---

## 🏗️ Plan Dev – Roadmap Source of Truth

### Objectif

Utiliser `chaine-de-dev.md` ou un index dédié comme roadmap mère, connectant tous les plans détaillés (sous-roadmaps), et garantir la navigation, la cohérence et l’actualisation régulière.

---

## 📋 Roadmap Granularisée

### 1. Recensement des roadmaps et plans détaillés

- [ ] Scanner tous les fichiers `plan-dev-*.md`, `ROADMAP.md`, `chaine-de-dev.md`
- [ ] Générer un inventaire des roadmaps existantes
- [ ] Livrable : `roadmaps_index.md`
- [ ] Script Go à créer : `cmd/roadmap-indexer/main.go`
- [ ] Critère de validation : index exhaustif

### 2. Analyse d’écart et structuration de l’index

- [ ] Comparer l’index réel à la navigation souhaitée (par thématique, manager, jalon)
- [ ] Identifier les roadmaps orphelines ou non référencées
- [ ] Livrable : `roadmap_gap_report.md`
- [ ] Critère de validation : rapport généré, écart < 5%

### 3. Spécification de la structure de l’index

- [ ] Définir la structure cible (table, liens, tags, dépendances)
- [ ] Rédiger un template Markdown pour l’index
- [ ] Livrable : `chaine-de-dev-template.md`
- [ ] Critère de validation : validé par revue croisée

### 4. Développement et génération de l’index

- [ ] Générer automatiquement l’index à partir de l’inventaire et du template
- [ ] Ajouter des tags/thématiques pour chaque roadmap
- [ ] Livrable : `projet/roadmaps/plans/consolidated/chaine-de-dev.md`
- [ ] Script Go à créer : `cmd/roadmap-index-generator/main.go`
- [ ] Critère de validation : index généré, liens valides

### 5. Tests et validation

- [ ] Tester la génération sur différents états du repo (ajout/suppression de roadmaps)
- [ ] Ajouter des tests unitaires pour chaque script Go
- [ ] Livrable : `*_test.go` pour chaque outil
- [ ] Commande : `go test ./cmd/roadmap-index-generator/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Reporting et feedback

- [ ] Générer un rapport d’exécution (logs, outputs, erreurs)
- [ ] Livrable : `index_generation_report.md`
- [ ] Script Go à créer : logging structuré avec Zap
- [ ] Critère de validation : logs archivés, feedback automatisé

### 7. Rollback et versionnement

- [ ] Sauvegarder les anciens index avant écrasement (`chaine-de-dev.bak`)
- [ ] Versionner chaque génération (`git commit -m "update roadmap index"`)
- [ ] Livrable : historique Git, fichiers `.bak`
- [ ] Critère de validation : possibilité de rollback immédiat

### 8. Intégration CI/CD

- [ ] Ajouter un job CI pour valider la génération de l’index à chaque PR
- [ ] Script d’orchestration : `scripts/ci/validate-roadmap-index.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification automatisée

### 9. Documentation et traçabilité

- [ ] Documenter chaque script et process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des modifications
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/roadmap-indexer/main.go

```go
package main

import (
    "fmt"
    "os"
    "io/ioutil"
)

func main() {
    files, err := ioutil.ReadDir("projet/roadmaps/plans/consolidated")
    if err != nil {
        panic(err)
    }
    for _, f := range files {
        if !f.IsDir() && len(f.Name()) > 10 && f.Name()[:8] == "plan-dev" {
            fmt.Println(f.Name())
        }
    }
}
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter la génération de l’index, notifier.
- Intégration CI/CD : pipeline pour valider la génération à chaque PR.
- Archivage automatique des index et logs.

---

## ✅ Checklist finale

- [ ] Index des roadmaps généré et validé
- [ ] Génération automatisée opérationnelle
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Rollback et traçabilité assurés
- [ ] Documentation technique à jour
