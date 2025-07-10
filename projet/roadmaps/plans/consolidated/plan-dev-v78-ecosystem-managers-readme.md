# plan-dev-v78-ecosystem-managers-readme.md

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

## 🏗️ Plan Dev – Ecosystem Managers README

### Objectif

Créer ou compléter un README unique et synthétique dans `.github/docs/` expliquant l’architecture, les interactions, les standards et l’état de chaque manager.

---

## 📋 Roadmap Granularisée

### 1. Recensement des managers et de leur documentation

- [ ] Générer la liste exhaustive des managers (`ls development/managers/`)
- [ ] Pour chaque manager, vérifier la présence d’un README et d’une roadmap
- [ ] Lister les API, dépendances, points d’intégration de chaque manager
- [ ] Livrable : tableau Markdown `managers_inventory.md`
- [ ] Script Go à créer : `cmd/manager-inventory/main.go` (scan, export CSV/MD)
- [ ] Critère de validation : tableau à jour, 100% des managers recensés

### 2. Analyse d’écart et recueil des besoins

- [ ] Comparer la liste réelle à la documentation existante (`.github/docs/MANAGERS/catalog-complete.md`)
- [ ] Identifier les managers manquants ou mal documentés
- [ ] Livrable : rapport d’écart `gap_analysis.md`
- [ ] Script Go à créer : `cmd/manager-gap-analysis/main.go`
- [ ] Critère de validation : rapport généré, écart < 5%

### 3. Spécification du README global

- [ ] Définir la structure cible du README (diagramme Mermaid, table, liens)
- [ ] Rédiger un template Markdown réutilisable
- [ ] Livrable : `README-template.md`
- [ ] Critère de validation : validé par revue croisée

### 4. Développement et génération du README

- [ ] Générer automatiquement le README à partir des inventaires et templates
- [ ] Intégrer un diagramme Mermaid généré (exemple Go : `github.com/knsv/mermaid`)
- [ ] Livrable : `.github/docs/MANAGERS/README.md`
- [ ] Script Go à créer : `cmd/manager-readme-generator/main.go`
- [ ] Critère de validation : README généré, liens valides, diagramme présent

### 5. Tests et validation

- [ ] Tester la génération sur différents états du repo (ajout/suppression de managers)
- [ ] Ajouter des tests unitaires pour chaque script Go
- [ ] Livrable : `*_test.go` pour chaque outil
- [ ] Commande : `go test ./cmd/manager-inventory/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Reporting et feedback

- [ ] Générer un rapport d’exécution (logs, outputs, erreurs)
- [ ] Livrable : `generation_report.md`
- [ ] Script Go à créer : logging structuré avec Zap
- [ ] Critère de validation : logs archivés, feedback automatisé

### 7. Rollback et versionnement

- [ ] Sauvegarder les anciens README avant écrasement (`README.bak`)
- [ ] Versionner chaque génération (`git commit -m "update managers readme"`)
- [ ] Livrable : historique Git, fichiers `.bak`
- [ ] Critère de validation : possibilité de rollback immédiat

### 8. Intégration CI/CD

- [ ] Ajouter un job CI pour valider la génération du README à chaque PR
- [ ] Script d’orchestration : `scripts/ci/validate-managers-readme.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification Slack/Teams

### 9. Documentation et traçabilité

- [ ] Documenter chaque script et process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des modifications
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/manager-inventory/main.go

```go
package main

import (
    "fmt"
    "os"
    "io/ioutil"
)

func main() {
    files, err := ioutil.ReadDir("development/managers")
    if err != nil {
        panic(err)
    }
    fmt.Println("| Manager | README | Roadmap |")
    fmt.Println("|---------|--------|---------|")
    for _, f := range files {
        if f.IsDir() {
            readme := "❌"
            roadmap := "❌"
            if _, err := os.Stat("development/managers/" + f.Name() + "/README.md"); err == nil {
                readme = "✅"
            }
            if _, err := os.Stat("development/managers/" + f.Name() + "/ROADMAP.md"); err == nil {
                roadmap = "✅"
            }
            fmt.Printf("| %s | %s | %s |\n", f.Name(), readme, roadmap)
        }
    }
}
```

### cmd/manager-gap-analysis/main.go

```go
// Compare la liste réelle à la doc catalog-complete.md et génère un rapport d’écart
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter tous les scripts, générer les rapports, notifier.
- Intégration CI/CD : pipeline GitHub Actions ou GitLab CI pour valider la génération, publier les artefacts, notifier l’équipe.
- Archivage automatique des rapports et logs.

---

## ✅ Checklist finale

- [ ] Tous les managers recensés et documentés
- [ ] README global généré et validé
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Rollback et traçabilité assurés
- [ ] Documentation technique à jour

---
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.
