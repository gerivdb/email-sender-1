# plan-dev-v81-no-duplication-standards.md

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

## 🏗️ Plan Dev – No Duplication of Standards

### Objectif

Faire respecter la règle : ne jamais dupliquer un standard déjà documenté dans `.github/docs` et garantir la centralisation des standards.

---

## 📋 Roadmap Granularisée

### 1. Recensement des standards existants

- [ ] Scanner `.github/docs/` pour lister tous les standards documentés
- [ ] Générer un inventaire des standards (formats, process, conventions)
- [ ] Livrable : `standards_inventory.md`
- [ ] Script Go à créer : `cmd/standards-inventory/main.go`
- [ ] Critère de validation : inventaire exhaustif

### 2. Analyse d’écart et détection des duplications

- [ ] Scanner tous les plans, scripts, docs pour repérer les duplications de standards
- [ ] Générer un rapport d’écart et de duplication
- [ ] Livrable : `duplication_report.md`
- [ ] Script Go à créer : `cmd/standards-duplication-check/main.go`
- [ ] Critère de validation : rapport généré, duplications listées

### 3. Spécification de la règle et du process

- [ ] Rédiger une section “Standards déjà couverts” à intégrer dans chaque plan/roadmap
- [ ] Documenter la règle dans le template roadmap et dans `.github/docs`
- [ ] Livrable : `standards_rule.md`, template mis à jour
- [ ] Critère de validation : validé par revue croisée

### 4. Automatisation de la vérification

- [ ] Créer un script Go pour vérifier automatiquement la présence de duplications dans chaque PR
- [ ] Intégrer la vérification dans le pipeline CI/CD
- [ ] Livrable : `cmd/standards-checker/main.go`, job CI
- [ ] Critère de validation : pipeline bloque toute duplication

### 5. Tests et validation

- [ ] Tester la détection sur différents cas (ajout, suppression, modification de standards)
- [ ] Ajouter des tests unitaires pour chaque script Go
- [ ] Livrable : `*_test.go` pour chaque outil
- [ ] Commande : `go test ./cmd/standards-checker/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Reporting et feedback

- [ ] Générer un rapport de vérification à chaque PR
- [ ] Livrable : `standards_check_report.md`
- [ ] Script Go à créer : logging structuré avec Zap
- [ ] Critère de validation : logs archivés, feedback automatisé

### 7. Rollback et versionnement

- [ ] Sauvegarder les anciens rapports avant écrasement (`standards_check_report.bak`)
- [ ] Versionner chaque rapport (`git commit -m "standards check report YYYYMMDD"`)
- [ ] Livrable : historique Git, fichiers `.bak`
- [ ] Critère de validation : possibilité de rollback immédiat

### 8. Intégration CI/CD

- [ ] Ajouter un job CI pour exécuter la vérification à chaque PR
- [ ] Script d’orchestration : `scripts/ci/standards-check.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification automatisée

### 9. Documentation et traçabilité

- [ ] Documenter chaque script et process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des vérifications
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/standards-inventory/main.go

```go
package main

import (
    "fmt"
    "os"
    "io/ioutil"
)

func main() {
    files, err := ioutil.ReadDir(".github/docs")
    if err != nil {
        panic(err)
    }
    for _, f := range files {
        if !f.IsDir() && (f.Name() != "" && (f.Name()[len(f.Name())-3:] == ".md")) {
            fmt.Println(f.Name())
        }
    }
}
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter les vérifications, générer les rapports, notifier.
- Intégration CI/CD : pipeline pour exécuter la vérification à chaque PR.
- Archivage automatique des rapports et logs.

---

## ✅ Checklist finale

- [ ] Inventaire des standards généré
- [ ] Vérification automatisée opérationnelle
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Rollback et traçabilité assurés
- [ ] Documentation technique à jour
