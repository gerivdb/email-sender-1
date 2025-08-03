# Roadmap actionnable – Structuration séquencée Roo-Code

## Checklist globale (cases à cocher, dépendances, scripts/tests)

- [ ] **Recensement**
    - [ ] Lancer [`.roo/scripts/recensement.go`](.roo/scripts/recensement.go:1)
    - [ ] Générer et valider `recensement.yaml`
    - [ ] Publier le rapport dans `.github/docs/incidents/`
- [ ] **Analyse d’écart**
    - [ ] Comparer `recensement.yaml` vs cible (`plan-dev-v107-rules-roo.md`)
    - [ ] Générer `rapport-ecart.md`
    - [ ] Valider la couverture des besoins
- [ ] **Recueil des besoins**
    - [ ] Organiser ateliers/entretiens (log dans `besoins-session.md`)
    - [ ] Compiler les besoins dans `besoins.yaml`
    - [ ] Valider avec les parties prenantes
- [ ] **Spécification**
    - [ ] Rédiger `spec-tech.md` (modèle Roo)
    - [ ] Générer les schémas/diagrammes Mermaid
    - [ ] Valider la conformité avec les besoins
- [ ] **Développement**
    - [ ] Implémenter les fonctionnalités (Go/TS)
    - [ ] Lancer [`.roo/scripts/dev-check.go`](.roo/scripts/dev-check.go:1)
    - [ ] Générer les tests unitaires
    - [ ] Mettre à jour la documentation technique
    - [ ] Valider via CI/CD (build, test, lint)
    - [ ] Appliquer et valider le correctif d’intégration terminal Roo Code ([`rapport-integration-terminal-roo-code.md`](.github/docs/roo/rapport-integration-terminal-roo-code.md:1), [`checklist-actionnable.md`](checklist-actionnable.md:1))
- [ ] **Tests**
    - [ ] Exécuter tous les tests (`go test ./...`, `npm test`)
    - [ ] Générer le rapport de couverture
    - [ ] Publier le rapport dans la roadmap
- [ ] **Reporting**
    - [ ] Compiler les rapports d’étape (`reporting.md`)
    - [ ] Générer le changelog
    - [ ] Diffuser aux parties prenantes
- [ ] **Validation collaborative**
    - [ ] Organiser la revue de code/plan
    - [ ] Collecter les retours et objections
    - [ ] Valider la version finale
- [ ] **Rollback**
    - [ ] Documenter la procédure dans `rollback.md`
    - [ ] Tester la restauration via RollbackManager
    - [ ] Archiver les états précédents

---

## Exemples de scripts/tests pour chaque étape

- [`.roo/scripts/recensement.go`](.roo/scripts/recensement.go:1) : scan, inventaire YAML/MD
- [`.roo/scripts/dev-check.go`](.roo/scripts/dev-check.go:1) : lint, tests, rapport Markdown
- `go test ./...` : exécution des tests Go
- `npm test` : exécution des tests TypeScript
- [`.roo/scripts/rollback.sh`](.roo/scripts/rollback.sh:1) : restauration d’un état validé

---

## Dépendances entre étapes

- Recensement → Analyse d’écart → Recueil des besoins → Spécification → Développement → Tests → Reporting → Validation → Rollback

---
## Orchestration & CI/CD

- Orchestrateur global : [`scripts/auto-roadmap-runner.go`](scripts/auto-roadmap-runner.go:1)
    - Exécute séquentiellement chaque étape de la checklist.
    - Gère les dépendances, l’état, les logs et le reporting.
    - Intègre la validation automatique et le feedback (succès/échec).
- Pipeline CI/CD : intégration avec GitHub Actions ou équivalent
    - Déclenchement automatique à chaque push/merge.
    - Étapes : build, lint, tests, publication des rapports, rollback si échec critique.
    - Génération automatique des badges de statut.
- Reporting automatisé :
    - Compilation des rapports d’étape et de couverture.
    - Diffusion automatique aux parties prenantes (mail, Slack, etc.).
    - Archivage dans `.github/docs/incidents/` et `reporting.md`.
- Feedback automatisé :
    - Notification en cas d’échec ou de succès d’étape.
    - Propositions d’alternatives en cas de blocage (voir section robustesse LLM).
    - Journalisation détaillée pour audit et traçabilité.

---

## Format de suivi

- Cases à cocher pour chaque sous-tâche
- Lien vers chaque livrable ou script
- Validation par artefact généré et log d’exécution

---

## À intégrer dans la CI/CD

- Exécution automatique des scripts Go/Bash à chaque push/PR
- Génération et archivage des rapports dans `.github/docs/incidents/` et la roadmap
- Feedback automatisé en cas d’échec (mail/Slack)

---

## Diagramme Mermaid (workflow complet)

```mermaid
flowchart TD
    A[Recensement] --> B[Analyse d'écart]
    B --> C[Recueil des besoins]
    C --> D[Spécification]
    D --> E[Développement]
    E --> F[Tests]
    F --> G[Reporting]
    G --> H[Validation collaborative]
    H --> I[Rollback]
## 🔒 Règles de robustesse LLM pour l’exécution automatisée

- **Étapes atomiques** : chaque action doit être découpée en unités minimales, testables indépendamment, sans effet de bord global.
- **Vérification systématique avant/après** : chaque étape inclut un script de vérification (Go/Bash) validant l’état attendu avant et après exécution.
- **Signalement automatique des échecs** : tout échec déclenche un log structuré, une notification (NotificationManager) et l’arrêt du pipeline.
- **Alternatives et rollback** : chaque étape critique propose une alternative automatisable et un script de rollback (`rollback-<étape>.go` ou `.sh`).
- **Limitation de la profondeur des modifications** : toute modification LLM ne doit pas dépasser le périmètre de l’étape courante ; interdiction des modifications globales non tracées.
- **Scripts Bash/Go pour toute action non automatisable** : si une action n’est pas automatisable par LLM, fournir un script Bash/Go documenté et testable.

**Exemple de structure pour une étape robuste :**
```markdown
- [ ] Étape X : Description
    - Script principal : `etape-x.go`
    - Script de vérification avant : `check-before-x.sh`
    - Script de vérification après : `check-after-x.sh`
    - Script de rollback : `rollback-x.go`
    - Critère de succès : sortie 0 + état validé par script de vérification
    - Critère d’échec : log structuré + notification + rollback
    - Alternative : `etape-x-alt.go` (si applicable)
```

**À intégrer pour chaque étape critique de la roadmap.**