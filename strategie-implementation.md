# Stratégie d'implémentation v113b

## Objectif
Garantir une implémentation actionnable, traçable, automatisée et reproductible de la phase 2 de la roadmap Roo Code v113b.

---

## Stratégies d’implémentation

- **Architecture et patterns** :  
  - Génération et validation de `architecture-automatisation-doc.md` et `diagramme-automatisation-doc.mmd` pour modéliser tous les patterns Roo (Session, Pipeline, Batch, Fallback, Monitoring, Audit, Rollback, UXMetrics, ProgressiveSync, Pooling, ReportingUI).
  - Utilisation de scripts Go reproductibles pour générer et synchroniser l’architecture et les diagrammes.
  - Validation croisée avec AGENTS.md et documentation centrale.

- **Recueil des besoins** :  
  - Génération automatisée de `feedback-utilisateur-v113b.md` via script Go ou formulaire markdown.
  - Archivage et versioning systématique du feedback utilisateur.

- **Spécification et schémas** :  
  - Génération automatique des schémas YAML/Markdown pour chaque pattern (`besoins-<pattern>.md`).
  - Lint YAML systématique (`yamllint <pattern>-schema-v113b.yaml`).
  - Archivage et commit Git à chaque étape.

- **Validation croisée et synchronisation** :  
  - Exécution de scripts de validation croisée entre AGENTS.md, la roadmap et les schémas.
  - Synchronisation automatique de la roadmap via RoadmapManager (`go run cmd/auto-roadmap-runner/main.go --sync`).

- **Documentation et traçabilité** :  
  - Mise à jour des guides techniques et du README à chaque étape clé.
  - Archivage des logs, schémas, feedbacks, diagrammes et artefacts.

- **Automatisation totale** :  
  - Toutes les tâches de la phase 2 sont réalisables par script Go, commande reproductible ou procédure documentée.
  - Aucun livrable manuel non traçable.

---

## Checklist actionnable (phase 2)

- [x] Générer `architecture-automatisation-doc.md`
- [x] Générer `diagramme-automatisation-doc.mmd`
- [x] Générer `feedback-utilisateur-v113b.md`
- [x] Générer `strategie-implementation.md` (ce fichier)
- [x] Générer tous les schémas YAML/Markdown de besoins (`besoins-<pattern>.md`)
- [ ] Linter tous les schémas YAML générés
- [ ] Valider la cohérence avec AGENTS.md (script de validation croisée)
- [ ] Synchroniser la roadmap via RoadmapManager
- [ ] Mettre à jour la documentation technique et le README
- [ ] Archiver tous les artefacts, logs, schémas, feedbacks, diagrammes
- [ ] Commit Git à chaque étape

---

## Liens et commandes reproductibles

- Génération architecture :  
  `go run scripts/gen_architecture_doc.go`
- Génération diagramme Mermaid :  
  `go run scripts/gen_mermaid_diagram.go`
- Génération feedback utilisateur :  
  `echo "# Feedback utilisateur v113b" > feedback-utilisateur-v113b.md`
- Génération schémas YAML/Markdown :  
  `go run scripts/recensement_exigences/main.go --pattern=<pattern>`
- Lint YAML :  
  `yamllint <pattern>-schema-v113b.yaml`
- Validation croisée AGENTS.md :  
  `go run scripts/validate_agents_crossref.go`
- Synchronisation roadmap :  
  `go run cmd/auto-roadmap-runner/main.go --sync`
- Archivage/commit :  
  `git add ... && git commit -m "feat(phase2): ..."`

---

## Signature & validation

- [ ] Stratégie relue et validée par : ______________________
- [ ] Date : ____/____/2025

---

**Ce document doit être mis à jour à chaque évolution de la phase 2 pour garantir la traçabilité, la conformité et l’actionnabilité du plan Roo Code v113b.**
