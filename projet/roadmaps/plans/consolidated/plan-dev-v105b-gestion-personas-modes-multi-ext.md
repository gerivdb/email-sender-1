# Plan de développement v1.05b — Gestion unifiée des personas/modes multi-extensions VSIX

## Table des matières
- [1. Backlog structuré](#1-backlog-structuré)
- [2. Roadmap et jalons](#2-roadmap-et-jalons)
- [3. Checklist détaillée](#3-checklist-détaillée)
- [4. Workflow d’exécution](#4-workflow-dexécution)
- [5. Suivi de validation](#5-suivi-de-validation)
- [6. Exemples de tickets et user stories](#6-exemples-de-tickets-et-user-stories)
- [7. Tableau de synthèse des actions et responsabilités](#7-tableau-de-synthèse-des-actions-et-responsabilités)

---

## 1. Backlog structuré

### Axe 1 — Référentiel centralisé des modes/personas
- Création du fichier YAML unique (`personas-modes-mapping.yaml`)
- Définition du schéma de données (attributs, équivalences, description)
- Recensement exhaustif des modes/personas existants dans chaque extension
- Versionnage et documentation initiale

### Axe 2 — Scripts/outils de synchronisation et validation
- Développement de scripts (Node.js/Python) pour :
  - Générer les mappings spécifiques à chaque extension
  - Valider la cohérence et l’exhaustivité
  - Détecter les divergences
- Intégration dans la CI/CD

### Axe 3 — Gouvernance et processus
- Constitution du comité multi-extensions
- Définition du processus de proposition/validation (PR, RFC, vote)
- Historisation des décisions et des évolutions
- Audit automatisé périodique

### Axe 4 — Documentation et traçabilité
- Rédaction de la documentation utilisateur et technique
- Génération automatique de la documentation à partir du YAML
- Liens systématiques vers les plans existants

---

## 2. Roadmap et jalons

| Jalon | Description | Dépendances | Livrables | Responsable | Critère de complétion |
|-------|-------------|-------------|-----------|-------------|-----------------------|
| M1 | Référentiel YAML initial | Aucun | `personas-modes-mapping.yaml` | Documentation Writer | YAML validé, exhaustif, versionné |
| M2 | Scripts de synchronisation/validation | M1 | Scripts Node.js/Python, tests | Code, DevOps | Scripts exécutables, tests passants |
| M3 | Mise en place CI/CD | M2 | Pipeline CI/CD, rapports | DevOps | Pipeline actif, rapports générés |
| M4 | Gouvernance opérationnelle | M1 | Comité, process validé, historique | Orchestrator | Comité constitué, process documenté |
| M5 | Documentation complète | M1, M2, M4 | Docs utilisateur/technique, liens | Documentation Writer | Docs publiées, traçabilité assurée |
| M6 | Audit automatisé | M3, M4 | Scripts d’audit, alertes | Security Reviewer | Audit périodique, alertes fonctionnelles |

---

## 3. Checklist détaillée

### Axe 1 — Référentiel centralisé
- [ ] Définir le schéma YAML cible
- [ ] Recenser tous les modes/personas existants
- [ ] Rédiger le fichier YAML initial
- [ ] Valider la structure et l’exhaustivité
- [ ] Versionner le référentiel

### Axe 2 — Scripts/outils
- [ ] Spécifier les besoins de synchronisation
- [ ] Développer les scripts de génération/validation
- [ ] Écrire les tests unitaires
- [ ] Intégrer les scripts à la CI/CD

### Axe 3 — Gouvernance
- [ ] Identifier les représentants de chaque extension
- [ ] Formaliser le processus de proposition/validation
- [ ] Mettre en place l’historisation des décisions
- [ ] Planifier les audits réguliers

### Axe 4 — Documentation
- [ ] Rédiger la documentation utilisateur
- [ ] Générer la documentation technique à partir du YAML
- [ ] Ajouter les liens vers les plans existants

---

## 4. Workflow d’exécution

1. **Initialisation**
   - Création du référentiel YAML
   - Validation par le comité
2. **Développement**
   - Écriture des scripts de synchronisation/validation
   - Tests unitaires et d’intégration
3. **Intégration**
   - Ajout des scripts à la CI/CD
   - Déploiement des pipelines
4. **Gouvernance**
   - Constitution du comité
   - Validation des évolutions par PR/RFC
   - Historisation et documentation
5. **Audit & Reporting**
   - Exécution régulière des scripts d’audit
   - Génération de rapports et alertes
6. **Documentation & Traçabilité**
   - Publication de la documentation
   - Mise à jour continue des liens et historiques

---

## 5. Suivi de validation

| Étape | Input attendu | Output produit | Outils/VSIX | Persona/Mode responsable | Critère de validation | Lien plan |
|-------|--------------|---------------|-------------|-------------------------|----------------------|-----------|
| Définition schéma YAML | Analyse besoins, plans existants | Schéma validé | VSCode, YAML Linter | Documentation Writer | Schéma validé par le comité | [`plan-dev-v105`](projet/roadmaps/plans/consolidated/plan-dev-v105-gestion-personas-modes-multi-ext.md:1) |
| Recensement modes | Inventaire extensions | Liste exhaustive | VSCode | Project Research | Liste validée | Idem |
| Génération YAML | Schéma, inventaire | YAML initial | VSCode | Documentation Writer | YAML exhaustif | Idem |
| Dév. scripts sync | YAML, specs | Scripts | Node.js/Python | Code | Scripts fonctionnels | Idem |
| Tests scripts | Scripts, YAML | Résultats tests | Jest, Pytest | Jest Test Engineer | 100% tests OK | Idem |
| CI/CD | Scripts, tests | Pipeline | GitHub Actions | DevOps | Pipeline actif | Idem |
| Gouvernance | Comité, process | Historique, process | VSCode, Markdown | Orchestrator | Process validé | Idem |
| Audit | Scripts, pipeline | Rapports, alertes | Node.js/Python | Security Reviewer | Alertes fonctionnelles | Idem |
| Documentation | YAML, scripts | Docs générées | VSCode | Documentation Writer | Docs publiées | Idem |

---

## 6. Exemples de tickets et user stories

### Ticket 1 — Création du référentiel YAML
- **Titre** : Générer le fichier `personas-modes-mapping.yaml`
- **Description** : Compiler la liste des modes/personas de chaque extension, définir le schéma, rédiger le YAML initial.
- **Input** : Plans existants, inventaire extensions
- **Output** : Fichier YAML versionné
- **Responsable** : Documentation Writer
- **Critère d’acceptation** : YAML exhaustif, validé par le comité

### Ticket 2 — Développement des scripts de synchronisation
- **Titre** : Développer les scripts de mapping multi-extensions
- **Description** : Écrire des scripts pour générer et valider les mappings à partir du YAML central.
- **Input** : YAML, specs
- **Output** : Scripts Node.js/Python, tests
- **Responsable** : Code, DevOps
- **Critère d’acceptation** : Scripts exécutables, 100% tests OK

### User Story — Gouvernance
- **En tant que** membre du comité multi-extensions
- **Je veux** valider chaque évolution du référentiel via PR/RFC
- **Afin de** garantir la cohérence et la traçabilité transverse

---

## 7. Tableau de synthèse des actions et responsabilités

| Action | Responsable | Dépendances | Livrable | Critère de complétion |
|--------|-------------|-------------|----------|----------------------|
| Définir schéma YAML | Documentation Writer | Analyse besoins | Schéma validé | Validation comité |
| Recenser modes/personas | Project Research | Extensions existantes | Liste exhaustive | Validation comité |
| Générer YAML initial | Documentation Writer | Schéma, inventaire | YAML versionné | Validation comité |
| Développer scripts sync | Code, DevOps | YAML | Scripts, tests | Exécution OK |
| Intégrer CI/CD | DevOps | Scripts, tests | Pipeline actif | Rapports générés |
| Constituer comité | Orchestrator | Aucun | Comité, process | Process documenté |
| Mettre en place audit | Security Reviewer | Scripts, pipeline | Rapports, alertes | Audit périodique |
| Rédiger documentation | Documentation Writer | YAML, scripts | Docs publiées | Publication docs |

---

**Liens utiles :**
- Plan source : [`plan-dev-v105-gestion-personas-modes-multi-ext.md`](projet/roadmaps/plans/consolidated/plan-dev-v105-gestion-personas-modes-multi-ext.md:1)
- Autres plans : [`plan-dev-v63-jan-cline-copilot.md`](plan-dev-v63-jan-cline-copilot.md:30), [`plan-dev-v86-meta-roadmap-harmonisation.md`](plan-dev-v86-meta-roadmap-harmonisation.md:51), [`plan-dev-v92-unification-modes-roomodes.md`](plan-dev-v92-unification-modes-roomodes.md:1), [`plan-dev-v99-gouvernance-modes-personas.md`](plan-dev-v99-gouvernance-modes-personas.md:1)