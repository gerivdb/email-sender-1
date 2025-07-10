# plan-dev-v83-cross-doc-traceability.md

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

## 🏗️ Plan Dev – Cross Documentation & Traceability

### Objectif

Systématiser la documentation croisée et la traçabilité entre plans, scripts, guides, pipelines et reporting pour garantir la cohérence, la maintenabilité et l’auditabilité de l’écosystème.

---

## 📋 Roadmap Granularisée

### 1. Recensement des liens et références croisées

- [ ] Scanner tous les plans, scripts, guides, pipelines pour recenser les liens internes et externes
- [ ] Générer un inventaire des références croisées
- [ ] Livrable : `cross_doc_inventory.md`
- [ ] Script Go à créer : `cmd/cross-doc-inventory/main.go`
- [ ] Critère de validation : inventaire exhaustif

### 2. Analyse d’écart et détection des ruptures de traçabilité

- [ ] Identifier les plans/scripts non référencés ou orphelins
- [ ] Générer un rapport d’écart de traçabilité
- [ ] Livrable : `traceability_gap_report.md`
- [ ] Script Go à créer : `cmd/traceability-gap-analysis/main.go`
- [ ] Critère de validation : rapport généré, ruptures listées

### 3. Spécification des conventions de documentation croisée

- [ ] Définir les conventions de liens, tags, sections “Références croisées”
- [ ] Rédiger un template à intégrer dans chaque plan/guide/script
- [ ] Livrable : `cross_doc_template.md`
- [ ] Critère de validation : validé par revue croisée

### 4. Automatisation de la génération et de la vérification

- [ ] Créer un script Go pour générer automatiquement les sections de documentation croisée
- [ ] Intégrer la vérification de la cohérence des liens dans le pipeline CI/CD
- [ ] Livrable : `cmd/cross-doc-generator/main.go`, job CI
- [ ] Critère de validation : pipeline bloque toute rupture de traçabilité

### 5. Tests et validation

- [ ] Tester la génération et la vérification sur différents cas (ajout, suppression, modification de liens)
- [ ] Ajouter des tests unitaires pour chaque script Go
- [ ] Livrable : `*_test.go` pour chaque outil
- [ ] Commande : `go test ./cmd/cross-doc-generator/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Reporting et feedback

- [ ] Générer un rapport de documentation croisée à chaque PR
- [ ] Livrable : `cross_doc_report.md`
- [ ] Script Go à créer : logging structuré avec Zap
- [ ] Critère de validation : logs archivés, feedback automatisé

### 7. Rollback et versionnement

- [ ] Sauvegarder les anciens rapports avant écrasement (`cross_doc_report.bak`)
- [ ] Versionner chaque rapport (`git commit -m "cross doc report YYYYMMDD"`)
- [ ] Livrable : historique Git, fichiers `.bak`
- [ ] Critère de validation : possibilité de rollback immédiat

### 8. Intégration CI/CD

- [ ] Ajouter un job CI pour exécuter la vérification à chaque PR
- [ ] Script d’orchestration : `scripts/ci/cross-doc-check.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification automatisée

### 9. Documentation et traçabilité

- [ ] Documenter chaque script et process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des vérifications
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/cross-doc-inventory/main.go

```go
package main

import (
    "fmt"
    "os"
    "io/ioutil"
    "strings"
)

func main() {
    files, err := ioutil.ReadDir("projet/roadmaps/plans/consolidated")
    if err != nil {
        panic(err)
    }
    for _, f := range files {
        if !f.IsDir() && strings.HasSuffix(f.Name(), ".md") {
            fmt.Printf("Fichier : %s\n", f.Name())
            // TODO: scanner les liens internes/externe dans chaque fichier
        }
    }
}
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter la génération et la vérification de la doc croisée, notifier.
- Intégration CI/CD : pipeline pour valider la cohérence des liens à chaque PR.
- Archivage automatique des rapports et logs.

---

## ✅ Checklist finale

- [ ] Inventaire des liens croisés généré
- [ ] Génération et vérification automatisées opérationnelles
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Rollback et traçabilité assurés
- [ ] Documentation technique à jour

---
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.

---
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.

---
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.
