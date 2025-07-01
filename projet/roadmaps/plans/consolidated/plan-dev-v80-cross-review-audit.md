# plan-dev-v80-cross-review-audit.md

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

## 🏗️ Plan Dev – Cross Review & Audit Automatisé

### Objectif

Mettre en place une routine de revue croisée (plans, scripts, docs) et un audit automatisé pour détecter doublons, divergences et incohérences dans l’écosystème.

---

## 📋 Roadmap Granularisée

### 1. Recensement des artefacts à auditer

- [ ] Scanner tous les plans, scripts, docs, configs (`find . -type f \( -name "*.md" -o -name "*.go" -o -name "*.ps1" \)`)
- [ ] Générer un inventaire des artefacts à auditer
- [ ] Livrable : `audit_inventory.md`
- [ ] Script Go à créer : `cmd/audit-inventory/main.go`
- [ ] Critère de validation : inventaire exhaustif

### 2. Analyse d’écart et détection des doublons/divergences

- [ ] Comparer les artefacts entre eux (hash, structure, contenu)
- [ ] Détecter les doublons de scripts, plans, sections de doc
- [ ] Livrable : `audit_gap_report.md`
- [ ] Script Go à créer : `cmd/audit-gap-analysis/main.go`
- [ ] Critère de validation : rapport généré, doublons listés

### 3. Spécification du process de revue croisée

- [ ] Définir la fréquence (mensuelle/trimestrielle)
- [ ] Documenter le process (pair review, réunion, async)
- [ ] Livrable : `cross_review_process.md`
- [ ] Critère de validation : process validé par l’équipe

### 4. Développement de l’audit automatisé

- [ ] Créer un script Go pour scanner, comparer, générer les rapports d’audit
- [ ] Intégrer la vérification de liens morts, incohérences de standards, etc.
- [ ] Livrable : `cmd/audit-runner/main.go`
- [ ] Critère de validation : audit automatisé, logs détaillés

### 5. Tests et validation

- [ ] Tester l’audit sur différents états du repo (ajout/suppression de plans/scripts)
- [ ] Ajouter des tests unitaires pour chaque script Go
- [ ] Livrable : `*_test.go` pour chaque outil
- [ ] Commande : `go test ./cmd/audit-runner/...`
- [ ] Critère de validation : couverture > 85%, tests passants

### 6. Reporting et feedback

- [ ] Générer un rapport d’audit à chaque cycle
- [ ] Livrable : `audit_report_YYYYMMDD.md`
- [ ] Script Go à créer : logging structuré avec Zap
- [ ] Critère de validation : logs archivés, feedback automatisé

### 7. Rollback et versionnement

- [ ] Sauvegarder les anciens rapports avant écrasement (`audit_report.bak`)
- [ ] Versionner chaque rapport d’audit (`git commit -m "audit report YYYYMMDD"`)
- [ ] Livrable : historique Git, fichiers `.bak`
- [ ] Critère de validation : possibilité de rollback immédiat

### 8. Intégration CI/CD

- [ ] Ajouter un job CI pour exécuter l’audit à chaque PR ou à intervalle régulier
- [ ] Script d’orchestration : `scripts/ci/auto-audit.sh`
- [ ] Badge de build à ajouter dans le README
- [ ] Critère de validation : pipeline vert, notification automatisée

### 9. Documentation et traçabilité

- [ ] Documenter chaque script et process dans le README technique
- [ ] Ajouter des logs détaillés et un historique des audits
- [ ] Livrable : `README.md`, changelog, logs
- [ ] Critère de validation : traçabilité complète, auditabilité

---

## 🧩 Exemples de scripts Go natifs

### cmd/audit-inventory/main.go

```go
package main

import (
    "fmt"
    "os"
    "path/filepath"
)

func main() {
    filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if !info.IsDir() && (filepath.Ext(path) == ".md" || filepath.Ext(path) == ".go" || filepath.Ext(path) == ".ps1") {
            fmt.Println(path)
        }
        return nil
    })
}
```

---

## 🛠️ Orchestration & CI/CD

- Orchestrateur global : `cmd/auto-roadmap-runner/main.go` pour exécuter les audits, générer les rapports, notifier.
- Intégration CI/CD : pipeline pour exécuter l’audit à chaque PR ou périodiquement.
- Archivage automatique des rapports et logs.

---

## ✅ Checklist finale

- [ ] Inventaire des artefacts généré
- [ ] Audit automatisé opérationnel
- [ ] Scripts Go natifs créés et testés
- [ ] CI/CD opérationnel
- [ ] Rollback et traçabilité assurés
- [ ] Documentation technique à jour
