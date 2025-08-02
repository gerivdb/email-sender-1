# Plan Dev v112 — Mode Code Go & Règle Primordiale main.go

---

## Phase 1 : Cadrage & Analyse

- **Objectif** : Formaliser un mode Roo “Code Go” et intégrer la règle primordiale Go pour `main.go`.
- **Livrables** : 
  - Fiche mode `code-go`
  - Spécification YAML du mode
  - Règle détaillée dans `.roo/rules-code-go/2_best_practices.xml`
- **Dépendances** : Documentation Roo, standards Go, retours utilisateurs.
- **Risques** : Oubli de cas limites, non-alignement avec la CI/CD, ambiguïtés sur l’isolation des exécutables.
- **Outils/Agents mobilisés** : Mode Writer, Code, CI/CD, tests unitaires.

### Tâches

- [x] Analyser la demande et les contraintes (règle Go + mode spécialisé)
- [x] Formaliser la règle Go à intégrer dans `rules-code.md`
- [x] Définir la fiche du mode spécialisé Code-Go
- [ ] Structurer le plan détaillé (ce fichier)
- [ ] Exporter le plan au format Markdown Roo

---

## Phase 2 : Définition du Mode Code-Go

- **Objectif** : Créer la fiche mode et la configuration YAML pour le mode “Code Go”.
- **Livrables** : 
  - `.roomodes` : fiche mode avec paramètre `go_primordial_rules`
  - Documentation XML `.roo/rules-code-go/2_best_practices.xml`
- **Dépendances** : Standards Roo, modèles existants.
- **Risques** : Mauvaise granularité des permissions, oubli de règles fondamentales Go.
- **Outils/Agents mobilisés** : Mode Writer, Code.

### Tâches

- [x] Lister les règles Go fondamentales (isolation main.go, arborescence, tests, linter, doc, sécurité…)
- [x] Générer la fiche YAML du mode
- [x] Générer la documentation XML structurée
- [ ] Valider la conformité avec les standards Roo et la documentation centrale

---

## Phase 3 : Intégration de la Règle main.go

- **Objectif** : Intégrer la règle “un seul main.go par exécutable Go dans un sous-dossier dédié” dans la documentation et la CI.
- **Livrables** : 
  - Section dédiée dans `rules-code.md`
  - Script de vérification automatique (CI)
  - Documentation utilisateur (README, guides)
- **Dépendances** : CI Roo, scripts existants.
- **Risques** : Non-détection de violations, faux positifs, documentation incomplète.
- **Outils/Agents mobilisés** : Code, CI/CD, tests.

### Tâches

- [x] Ajouter la règle dans `rules-code.md`
- [ ] Ajouter un script de vérification automatique dans la CI
- [ ] Mettre à jour la documentation utilisateur et README

---

## Phase 4 : Validation, Rollback & Documentation

- **Objectif** : Valider l’intégration, prévoir rollback, documenter les cas limites.
- **Livrables** : 
  - Checklist de validation
  - Procédure de rollback
  - Documentation des cas limites dans `.roo/rules-code-go/3_common_patterns.xml`
- **Dépendances** : Feedback utilisateur, tests CI.
- **Risques** : Oubli de rollback, documentation non-actionnable.
- **Outils/Agents mobilisés** : Code, Documentation Writer.

### Tâches

- [ ] Valider la conformité via tests et feedback
- [ ] Documenter la procédure de rollback
- [ ] Ajouter les cas limites et patterns dans la documentation XML

---

## Critères de validation

- Plan structuré, séquencé, actionnable et conforme au template Roo
- Règle main.go intégrée dans la documentation et la CI
- Mode Code-Go opérationnel et documenté
- Procédures de rollback et cas limites présents
- Documentation utilisateur à jour

---

## Rollback/versionning

- Sauvegarde automatique avant modification des règles
- Script de restauration de l’état précédent
- Documentation des étapes de rollback dans `.roo/rules-code-go/3_common_patterns.xml`

---

## Orchestration & CI/CD

- Intégration du script de vérification dans le pipeline CI Roo
- Badge de conformité “Go Mode” dans le README
- Monitoring automatisé des violations de la règle main.go

---

## Documentation & traçabilité

- Mise à jour du README et des guides utilisateurs
- Liens croisés vers la fiche mode, la règle et la documentation XML
- Reporting automatique des violations et correctifs

---

## Questions ouvertes, hypothèses & ambiguïtés

- Hypothèse : Tous les exécutables Go sont isolés dans un sous-dossier dédié.
- Question : Faut-il gérer les cas legacy où plusieurs main.go coexistent ?
- Ambiguïté : Quid des scripts/outils Go non standards ?

---

## Auto-critique & raffinement

- Limite : Le plan ne couvre pas les cas multi-langages ou monorepo complexes.
- Suggestion : Ajouter une étape d’audit automatique pour détecter les cas non couverts.
- Feedback : Intégrer un agent LLM pour suggérer des améliorations continues sur la structuration Go.

---

## Références croisées

- [rules-code.md](.roo/rules/rules-code.md)
- [AGENTS.md](AGENTS.md)
- [plan-dev-v107-rules-roo.md](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- [plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)
- [workflows-matrix.md](.roo/rules/workflows-matrix.md)
