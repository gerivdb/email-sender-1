# plan-dev-v79-roadmap-template.md

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

## 🏗️ Plan Dev – Roadmap Template Standard

### Objectif

Concevoir, documenter et imposer un template unique, modulaire et automatisable pour toutes les roadmaps et plans du dépôt.

---

## 📋 Roadmap Granularisée

### 1. Recensement des roadmaps et plans existants

- [ ] Scanner tous les fichiers `plan-dev-*.md` et `ROADMAP.md`
- [ ] Générer un inventaire des structures utilisées
- [ ] Livrable : `roadmaps_inventory.md`
- [ ] Script Go à créer : `cmd/roadmap-inventory/main.go`
- [ ] Critère de validation : inventaire exhaustif

### 2. Analyse d’écart et recueil des besoins

- [ ] Comparer les structures existantes au standard souhaité
- [ ] Recueillir les besoins auprès des contributeurs (feedback, interviews)
- [ ] Livrable : `roadmap_gap_analysis.md`
- [ ] Critère de validation : rapport validé par l’équipe

### 3. Spécification du template

- [ ] Définir la structure cible (objectifs, sous-tâches, livrables, scripts/tests, validation, rollback, CI/CD, doc, traçabilité)
- [ ] Rédiger le template Markdown réutilisable
- [ ] Livrable : `template-roadmap.md`
- [ ] Critère de validation : validé par revue croisée

### 4. Développement et automatisation

- [ ] Créer un script Go pour générer une nouvelle roadmap à partir du template
- [ ] Ajouter des options CLI pour personnaliser le nom, la date, les sections
- [ ] Livrable : `cmd/roadmap-generator/main.go`
- [ ] Critère de validation : génération automatisée, template conforme

### 5. Tests et validation

- [ ] Tester la génération sur différents cas (roadmap simple, complexe)
- [ ] Ajouter des tests unitaires pour le script Go
- [ ] Livrable : `roadmap_generator_test.go`
- [ ] Commande : `go test ./cmd/roadmap-generator/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Intégration CI/CD

- [ ] Ajouter un job CI pour valider la conformité des nouvelles roadmaps
- [ ] Script d’orchestration : `scripts/ci/validate-roadmap-template.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification automatisée

### 7. Documentation et traçabilité

- [ ] Documenter le template, le script et le process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des générations
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/roadmap-generator/main.go

```go
package main

import (
    "fmt"
    "os"
    "text/template"
)

func main() {
    tmpl, err := template.ParseFiles("template-roadmap.md")
    if err != nil {
        panic(err)
    }
    f, err := os.Create("plan-dev-vXX-new-feature.md")
    if err != nil {
        panic(err)
    }
    data := struct {
        Name string
        Date string
    }{
        Name: "Nouvelle fonctionnalité",
        Date: "2025-07-01",
    }
    tmpl.Execute(f, data)
    fmt.Println("Nouvelle roadmap générée.")
}
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter les scripts de génération et de validation.
- Intégration CI/CD : pipeline pour vérifier la conformité des roadmaps à chaque PR.
- Archivage automatique des templates et logs.

---

## ✅ Checklist finale

- [ ] Template unique conçu et validé
- [ ] Génération automatisée opérationnelle
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Documentation technique à jour
- [ ] Traçabilité et rollback assurés

---
## Note d'architecture
Ce plan est conforme à l'architecture actuelle.
