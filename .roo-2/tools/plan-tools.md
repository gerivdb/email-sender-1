# Roadmap exhaustive et automatisable pour le développement du tool de synchronisation des références croisées Roo-Code

---

## Objectif

Développer un outil Go natif (`refs_sync.go`) pour automatiser la gestion, la mise à jour et l’audit des références croisées entre les fichiers de règles Roo-Code, en garantissant robustesse, traçabilité, automatisation maximale et intégration CI/CD.

---

## 🗂️ Découpage en étapes actionnables

### 1. Recensement & Analyse d’écart

- [x] **Recenser tous les fichiers de règles à synchroniser**
  - Livrable : `files-list.json`, log Markdown
  - Commande : `go run refs_sync.go --scan`
  - Script : scan du dossier `.roo/rules/`, exclusion configurable
  - Format : JSON, Markdown
  - Validation : fichier généré, log, test unitaire sur la détection
  - Rollback : sauvegarde de la liste précédente (`files-list.bak`)
  - CI/CD : job de scan, badge "Scan OK"
  - Documentation : section "Scan automatique" dans README
  - Traçabilité : log d’exécution, historique des scans

- [x] **Analyser l’écart entre les références existantes et attendues**
  - Livrable : `crossrefs-gap-report.md`
  - Commande : `go run refs_sync.go --audit`
  - Script : comparaison des sections "Références croisées" existantes vs attendues
  - Format : Markdown, CSV
  - Validation : rapport d’écart, test automatisé
  - Rollback : rapport archivé
  - CI/CD : job d’audit, notification si écart détecté
  - Documentation : exemple de rapport d’écart
  - Traçabilité : log, archivage des rapports

### 2. Recueil des besoins & Spécification

- [x] **Recueillir les besoins d’inclusion/exclusion, format, personnalisation**
  - Livrable : `refs_sync.config.yaml`
  - Commande : édition manuelle ou via script interactif
  - Script : générateur de config, validation syntaxique
  - Format : YAML
  - Validation : test de parsing, feedback utilisateur
  - Rollback : version précédente du fichier
  - CI/CD : validation de la config à chaque run
  - Documentation : guide de configuration
  - Traçabilité : historique des configs

- [x] **Spécifier les formats de section, l’ordre, les dépendances**
  - Livrable : `spec-crossrefs.md`
  - Commande : `go run refs_sync.go --spec`
  - Script : générateur de spécification à partir de la config
  - Format : Markdown
  - Validation : revue croisée, test de conformité
  - Rollback : version précédente
  - CI/CD : job de validation de spec
  - Documentation : exemple de section générée
  - Traçabilité : log, archivage

### 3. Développement & Automatisation

- [x] **Développer le module de scan et de génération**
  - Livrable : `refs_sync.go`, tests `refs_sync_test.go`
  - Commande : `go build`, `go test`
  - Script : Go natif, modularisé
  - Format : Go, Markdown, JSON
  - Validation : couverture >90%, badge CI
  - Rollback : commit git, backup automatique
  - CI/CD : build/test automatique, badge
  - Documentation : README usage, exemples
  - Traçabilité : logs, historique des runs

- [x] **Développer le module d’injection/mise à jour intelligente**
  - Livrable : fonction Go, tests associés
  - Commande : `go run refs_sync.go --inject`
  - Script : injection en fin de fichier, détection des doublons, positionnement correct
  - Format : Markdown
  - Validation : test d’intégration, revue croisée
  - Rollback : sauvegarde `.bak` avant modification
  - CI/CD : test d’injection, notification en cas d’échec
  - Documentation : guide d’injection
  - Traçabilité : log, backup, historique

- [x] **Développer le module de vérification des verrous/droits**
  - Livrable : fonction Go, tests
  - Commande : `go run refs_sync.go --check-locks`
  - Script : vérification accès, gestion des fichiers verrouillés
  - Format : log Markdown
  - Validation : test unitaire, rapport
  - Rollback : rapport archivé
  - CI/CD : job de vérification
  - Documentation : section "Gestion des verrous"
  - Traçabilité : log, rapport

- [x] **Développer le mode dry-run/audit**
  - Livrable : option CLI, rapport Markdown
  - Commande : `go run refs_sync.go --dry-run`
  - Script : simulation sans écriture
  - Format : Markdown
  - Validation : test dry-run, rapport
  - Rollback : aucun impact
  - CI/CD : job dry-run, badge
  - Documentation : guide dry-run
  - Traçabilité : log, rapport

### 4. Tests (unitaires, intégration, robustesse)

- [x] **Écrire des tests unitaires pour chaque module**
  - Livrable : `refs_sync_test.go`
  - Commande : `go test -v -cover`
  - Script : Go natif, mocks pour accès disque
  - Format : Go
  - Validation : couverture >90%, badge
  - Rollback : suppression des tests défaillants
  - CI/CD : job test, badge
  - Documentation : README tests
  - Traçabilité : log, rapport de couverture

- [x] **Écrire des tests d’intégration (workflow complet)**
  - Livrable : scénario Markdown, script Go
  - Commande : `go run refs_sync.go --full-test`
  - Script : simulation de bout en bout
  - Format : Markdown, Go
  - Validation : rapport, badge
  - Rollback : backup avant test
  - CI/CD : job intégration
  - Documentation : guide d’intégration
  - Traçabilité : log, rapport

### 5. Reporting, Validation & Rollback

- [x] **Générer des rapports d’exécution et d’audit**
  - Livrable : `refs_sync_report.md`, logs
  - Commande : `go run refs_sync.go --report`
  - Script : génération automatique
  - Format : Markdown, CSV
  - Validation : revue croisée, feedback automatisé
  - Rollback : archivage des rapports
  - CI/CD : job reporting, notification
  - Documentation : exemple de rapport
  - Traçabilité : log, historique

- [x] **Procédures de rollback/versionnement**
  - Livrable : backups `.bak`, commits git
  - Commande : `cp file file.bak`, `git commit`
  - Script : backup avant modification, revert possible
  - Format : fichiers originaux, backups
  - Validation : test de restauration
  - CI/CD : job backup, badge
  - Documentation : guide rollback
  - Traçabilité : log, historique des backups

### 6. Orchestration & CI/CD

- [x] **Créer un orchestrateur global**
  - Livrable : `auto-roadmap-runner.go`
  - Commande : `go run auto-roadmap-runner.go`
  - Script : exécution séquentielle de tous les jobs, gestion des dépendances
  - Format : Go, logs
  - Validation : rapport global, badge
  - Rollback : backup orchestrateur
  - CI/CD : pipeline dédié, triggers, reporting
  - Documentation : README orchestrateur
  - Traçabilité : log, rapport

- [x] **Intégrer dans le pipeline CI/CD**
  - Livrable : `.github/workflows/refs_sync.yml`
  - Commande : jobs scan, audit, inject, test, report
  - Script : YAML, Go
  - Format : YAML, Markdown
  - Validation : badge, notification
  - Rollback : revert workflow
  - Documentation : guide CI/CD
  - Traçabilité : logs, rapports CI

### 7. Documentation & Traçabilité

- [x] **Rédiger la documentation technique et utilisateur**
  - Livrable : `README.md`, guides, FAQ
  - Commande : édition Markdown
  - Script : générateur d’exemples
  - Format : Markdown, HTML
  - Validation : revue croisée
  - Rollback : version précédente
  - CI/CD : job doc, badge
  - Documentation : complète, exemples, troubleshooting
  - Traçabilité : log, historique

- [x] **Assurer la traçabilité complète**
  - Livrable : logs, historiques, rapports archivés
  - Commande : automatisation dans scripts
  - Script : loggers Go, archivage
  - Format : Markdown, JSON
  - Validation : vérification des logs
  - Rollback : archivage
  - CI/CD : job archivage
  - Documentation : guide traçabilité
  - Traçabilité : logs, rapports

---

## 🔧 Exemples de scripts Go natifs

### Scan des fichiers

```go
// refs_sync.go (extrait)
func ScanRulesDir(dir string) ([]string, error) {
    // Scan du dossier, retourne la liste des fichiers .md à synchroniser
}
```

### Injection de section

```go
func InjectCrossRefsSection(filePath string, refs []string) error {
    // Ajoute ou met à jour la section "Références croisées" en fin de fichier
}
```

### Test unitaire

```go
func TestScanRulesDir(t *testing.T) {
    // Mock du dossier, vérifie la détection des fichiers
}
```

---

## 🏁 Robustesse & Adaptation LLM

- Actions atomiques, vérification avant/après chaque modification
- Confirmation requise avant toute modification de masse
- Limitation de la profondeur des modifications
- Signalement immédiat en cas d’échec, alternative proposée
- Scripts Bash ou commandes manuelles proposés si automatisation impossible
- Passage en mode ACT explicitement indiqué si nécessaire

---

## ✅ Checklist globale

- [ ] Recensement des fichiers
- [ ] Audit des écarts
- [ ] Recueil des besoins/configuration
- [ ] Spécification des formats
- [ ] Développement des modules Go
- [ ] Tests unitaires et d’intégration
- [ ] Reporting et rollback
- [ ] Orchestration globale
- [ ] Intégration CI/CD
- [ ] Documentation complète
- [ ] Traçabilité et archivage

---

## 📦 Dépendances et conventions

- Stack Go natif prioritaire
- Arborescence modulaire `.roo/tools/`
- Documentation et tests dans chaque module
- Reporting et logs systématiques
- Standards `.clinerules/` : granularité, documentation, validation croisée, versionnement, traçabilité, automatisation maximale

---
