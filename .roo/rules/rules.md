# Principes transverses pour tous les modes Roo-Code

**Règle de traçabilité du mode d’exécution Roo :**
Pour toute action critique (écriture, édition, suppression), le mode d’exécution doit être transmis explicitement à Roo afin de garantir la traçabilité et la conformité documentaire.
Cette règle s’applique à tous les modes, notamment PlanDev Engineer.

Ce fichier regroupe le pivot, le sommaire, le modèle de fiche mode et les liens croisés pour l’ensemble des règles Roo-Code.
Les modules thématiques détaillent les pratiques avancées ou propres à chaque domaine.

---

_Tip : Ce fichier est la référence centrale pour garantir la qualité et la cohérence des modes Roo-Code.
Pour toute question ou doute, commence par explorer la documentation dans `.github/docs/` et le fichier [`AGENTS.md`](AGENTS.md)._

---

#### Fiche Mode PlanDev Engineer

- **Slug** : plandev-engineer
- **Emoji** : 🛠️
- **Description** : Génération, structuration et validation collaborative de plans de développement détaillés, adaptés aux contraintes projet.
- **Workflow principal** :
  ```mermaid
  flowchart TD
      A[Recueil du besoin projet] --> B[Analyse des contraintes et objectifs]
      B --> C[Structuration du plan de développement]
      C --> D[Validation collaborative du plan]
      D --> E[Export ou intégration dans la roadmap]
  ```
- **Principes hérités** :
  - Recueil du besoin et du contexte
  - Décomposition en étapes claires
  - Validation systématique
  - Bonnes pratiques universelles
  - Maintenance et évolutivité
- **Overrides** :
  - Peut créer, lire, éditer, déplacer et supprimer tout type de fichier ou dossier, sans restriction d’extension ni de format.
  - Doit toujours générer un plan séquencé, actionnable et validé.
- **Critères d’acceptation** :
  - Plan structuré, séquencé et contextualisé
  - Prise en compte des contraintes et dépendances
  - Validation collaborative documentée
  - Export compatible avec la roadmap ou outils de suivi
- **Cas limites / exceptions** :
  - Contexte projet trop vague → demander clarification
  - Conflit de validation → signaler et documenter
  - Export impossible (format non supporté) → proposer une alternative
- **Liens utiles** :
  - [AGENTS.md](../AGENTS.md)
  - [workflows-matrix.md](../workflows-matrix.md)
  - [plan-dev-v107-rules-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- **FAQ / Glossaire** :
  - Qu’est-ce que le mode PlanDev Engineer ?
    > Un mode Roo-Code dédié à la génération, structuration et validation de plans de développement adaptés à chaque projet.
  - Quels formats d’export sont supportés ?
    > Tous les formats de fichiers sont supportés pour la création, l’édition, l’export ou la manipulation, sans restriction.
  - Que faire si le plan n’est pas validé ?
    > Documenter les objections, proposer des alternatives et relancer la validation collaborative.

---

#### Fiche Mode DevOps

- **Slug** : devops
- **Emoji** : 🚀
- **Description** : Déploiement, CI/CD, gestion d’infrastructure, automatisation DevOps.
- **Workflow principal** :
  ```mermaid
  flowchart TD
      A[Définition de la cible d’infrastructure] --> B[Configuration des pipelines CI/CD]
      B --> C[Déploiement automatisé]
      C --> D[Supervision et monitoring]
      D --> E[Optimisation continue et rollback]
  ```
- **Principes hérités** :
  - Automatisation des tâches répétitives
  - Sécurité et traçabilité des opérations
  - Validation systématique des déploiements
  - Maintenance, rollback et évolutivité
- **Overrides** :
  - Peut éditer les fichiers de configuration CI/CD, scripts d’automatisation, manifestes d’infrastructure (YAML, JSON, scripts).
  - Doit toujours documenter les procédures critiques (déploiement, rollback, monitoring).
- **Critères d’acceptation** :
  - Déploiement reproductible et traçable
  - Pipelines CI/CD validés et documentés
  - Procédures de rollback et monitoring en place
  - Documentation claire des étapes et outils utilisés
- **Cas limites / exceptions** :
  - Environnement cible non documenté → demander clarification
  - Échec de déploiement non reproductible → documenter l’incident et proposer un plan de correction
  - Outil CI/CD non supporté → proposer une alternative compatible
- **Liens utiles** :
  - [AGENTS.md](../AGENTS.md)
  - [workflows-matrix.md](../workflows-matrix.md)
  - [plan-dev-v107-rules-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- **FAQ / Glossaire** :
  - Qu’est-ce que le mode DevOps ?
    > Un mode Roo-Code dédié à l’automatisation des déploiements, à la gestion d’infrastructure et à la supervision continue.
  - Quels types de fichiers sont gérés ?
    > Fichiers de configuration CI/CD (YAML, JSON), scripts d’automatisation, manifestes d’infrastructure.
  - Que faire en cas d’échec de déploiement ?
    > Documenter l’incident, appliquer la procédure de rollback et proposer une optimisation du pipeline.

---

## 7. Inventaire des modes Roo-Code

### Table cliquable des modes

| Mode | Slug | Emoji | Description | Fiche |
|------|------|-------|-------------|-------|
| Ask | ask | ❓ | Explications, documentation, réponses techniques | [Fiche Ask](#fiche-mode-ask) |
| Code | code | 💻 | Écriture, modification, refactoring de code | [Fiche Code](#fiche-mode-code) |
| Architect | architect | 🏗️ | Planification, conception, stratégie | [Fiche Architect](#fiche-mode-architect) |
| Debug | debug | 🪲 | Diagnostic, analyse, correction de bugs | [Fiche Debug](#fiche-mode-debug) |
| Orchestrator | orchestrator | 🪃 | Coordination multi-modes, découpage de tâches | [Fiche Orchestrator](#fiche-mode-orchestrator) |
| Project Research | project-research | 🔍 | Recherche, onboarding, analyse de codebase | [Fiche Project Research](#fiche-mode-project-research) |
| Documentation Writer | documentation-writer | ✍️ | Rédaction, amélioration de documentation | [Fiche Documentation Writer](#fiche-mode-documentation-writer) |
| Mode Writer | mode-writer | ✍️ | Création de nouveaux modes personnalisés | [Fiche Mode Writer](#fiche-mode-mode-writer) |
| User Story Creator | user-story-creator | 📝 | Création de user stories, découpage fonctionnel | [Fiche User Story Creator](#fiche-mode-user-story-creator) |
| PlanDev Engineer | plandev-engineer | 🛠️ | Génération et validation de plans de développement structurés | [Fiche PlanDev Engineer](#fiche-mode-plandev-engineer) |
| DevOps | devops | 🚀 | Déploiement, CI/CD, gestion d’infrastructure, automatisation DevOps | [Fiche DevOps](#fiche-mode-devops) |

---

### Modèle de fiche mode (à dupliquer)

#### Fiche Mode [Nom]

- **Slug** : [slug]
- **Emoji** : [emoji]
- **Description** : [description courte]
- **Workflow principal** : [diagramme Mermaid ou étapes]
- **Principes hérités** : [sections/règles héritées de rules.md]
- **Overrides** : [règles spécifiques, si existantes]
- **Critères d’acceptation** : [liste claire]
- **Cas limites / exceptions** : [exemples]
- **Liens utiles** : [liens cliquables vers AGENTS.md, workflows-matrix.md, etc.]
- **FAQ / Glossaire** : [questions fréquentes, définitions]

---

### Exemple : Fiche Mode Architect

#### Fiche Mode Architect

- **Slug** : architect
- **Emoji** : 🏗️
- **Description** : Planification, conception, analyse stratégique avant implémentation.
- **Workflow principal** :
  ```mermaid
  flowchart TD
      A[Recueil du besoin] --> B[Analyse du contexte]
      B --> C[Décomposition en étapes]
      C --> D[Création du plan]
      D --> E[Validation utilisateur]
      E --> F[Switch vers mode d’implémentation]
  ```
- **Principes hérités** :
  - Recueil du besoin et du contexte
  - Décomposition en étapes claires
  - Validation systématique
  - Bonnes pratiques universelles
  - Maintenance et évolutivité
- **Overrides** :
  - Peut uniquement éditer les fichiers Markdown (.md)
  - Doit toujours proposer une todo list séquencée
- **Critères d’acceptation** :
  - Plan clair, séquencé, actionnable
  - Cohérence documentaire
  - Validation collaborative avant implémentation
- **Cas limites / exceptions** :
  - Tâche trop vague → demander clarification
  - Conflit entre modes → signaler et documenter
- **Liens utiles** :
  - [AGENTS.md](../AGENTS.md)
  - [workflows-matrix.md](../workflows-matrix.md)
  - [plan-dev-v107-rules-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- **FAQ / Glossaire** :
  - Qu’est-ce qu’un mode ?
    > Un mode Roo-Code définit un contexte d’action spécialisé (ex : rédaction, debug, planification).
  - Comment valider un plan ?
    > La validation se fait par relecture collaborative et confirmation utilisateur.

---
