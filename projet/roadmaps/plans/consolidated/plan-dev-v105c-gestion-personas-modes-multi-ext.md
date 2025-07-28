# Plan de développement v1.05c — Gouvernance & synchronisation ultra-granulaire des personas/modes multi-extensions VSIX

## 1. Introduction

Ce plan vise à fournir une feuille de route actionnable, hiérarchisée jusqu’à 10 niveaux, pour la gouvernance, la synchronisation et l’extension des personas/modes dans un écosystème multi-VSIX (Kilo Code, Roomodes, Copilot, Cline…). Il s’appuie sur les plans existants ([`plan-dev-v105`](projet/roadmaps/plans/consolidated/plan-dev-v105-gestion-personas-modes-multi-ext.md:1), [`plan-dev-v105b`](projet/roadmaps/plans/consolidated/plan-dev-v105b-gestion-personas-modes-multi-ext.md:1)), et garantit la conformité aux principes SOLID, DRY, KISS et à la logique de pilotage manager.

---

## 2. Arborescence détaillée des axes et sous-axes

### 1. Référentiel centralisé des modes/personas

#### 1.1. Définition du schéma cible
- **Objectif** : Spécifier la structure du fichier YAML central.
- **Input** : Analyse besoins, plans existants.
- **Output** : Schéma YAML validé.
- **Critères** : Schéma validé par le comité, extensible.
- **Dépendances** : Aucun.
- **Outils/VSIX** : VSCode, YAML Linter.
- **Persona/Mode** : Documentation Writer.
- **Lien** : [`plan-dev-v105b`](projet/roadmaps/plans/consolidated/plan-dev-v105b-gestion-personas-modes-multi-ext.md:58)
- **Exemple** :  
  - Ticket : « Définir le schéma YAML cible »
  - Script : `yamllint personas-modes-mapping.yaml`

##### 1.1.1. Recensement des attributs nécessaires
- **Objectif** : Lister tous les champs requis (canonical, équivalences, description…).
- **Input** : Inventaire extensions.
- **Output** : Liste d’attributs.
- **Critères** : Exhaustivité.
- **Dépendances** : 1.1.
- **Outils/VSIX** : Tableur, VSCode.
- **Persona/Mode** : Project Research.
- **Exemple** :  
  - User story : « En tant que Project Research, je veux inventorier tous les attributs pour garantir la couverture fonctionnelle. »

##### 1.1.1.1. Validation des attributs par le comité
- **Objectif** : Obtenir l’accord multi-extensions.
- **Input** : Liste d’attributs.
- **Output** : Validation formelle.
- **Critères** : Accord de tous les représentants.
- **Dépendances** : 1.1.1.
- **Outils/VSIX** : Markdown, VSCode.
- **Persona/Mode** : Orchestrator.
- **Exemple** :  
  - Ticket : « Valider la liste des attributs en comité »

#### 1.2. Recensement exhaustif des modes/personas existants

##### 1.2.1. Extraction automatisée des modes/personas par extension
- **Objectif** : Générer la liste à jour pour chaque VSIX.
- **Input** : Code source, docs extensions.
- **Output** : Fichiers d’inventaire.
- **Critères** : 100% des modes/personas recensés.
- **Dépendances** : 1.1.1.1.
- **Outils/VSIX** : Scripts Node.js/Python.
- **Persona/Mode** : Code, Project Research.
- **Exemple** :  
  - Script : `node extract-modes.js`
  - Ticket : « Automatiser l’extraction des modes Roomodes »

##### 1.2.1.1. Consolidation et dédoublonnage
- **Objectif** : Fusionner, éliminer les doublons.
- **Input** : Fichiers d’inventaire.
- **Output** : Liste consolidée.
- **Critères** : Zéro doublon.
- **Dépendances** : 1.2.1.
- **Outils/VSIX** : Tableur, script Python.
- **Persona/Mode** : Documentation Writer.
- **Exemple** :  
  - Script : `python deduplicate_modes.py`

#### 1.3. Rédaction et versionnage du YAML initial
- **Objectif** : Écrire le fichier central.
- **Input** : Schéma validé, liste consolidée.
- **Output** : `personas-modes-mapping.yaml` versionné.
- **Critères** : YAML exhaustif, validé.
- **Dépendances** : 1.2.1.1.
- **Outils/VSIX** : Git, VSCode.
- **Persona/Mode** : Documentation Writer.
- **Exemple** :  
  - Ticket : « Rédiger le YAML initial »
  - Commande : `git commit -m "Ajout YAML centralisé"`

---

### 2. Scripts/outils de synchronisation et validation

#### 2.1. Spécification des besoins de synchronisation
- **Objectif** : Définir les flux de synchronisation inter-extensions.
- **Input** : Schéma YAML, plans existants.
- **Output** : Spécifications techniques.
- **Critères** : Spécifications validées.
- **Dépendances** : 1.3.
- **Outils/VSIX** : Markdown, VSCode.
- **Persona/Mode** : Code, DevOps.
- **Lien** : [`plan-dev-v105b`](projet/roadmaps/plans/consolidated/plan-dev-v105b-gestion-personas-modes-multi-ext.md:65)
- **Exemple** :  
  - Ticket : « Spécifier les flux de synchronisation multi-VSIX »

##### 2.1.1. Définition des formats cibles par extension
- **Objectif** : Formaliser les formats attendus (JSON, YAML, etc.).
- **Input** : Docs extensions.
- **Output** : Spécifications formats.
- **Critères** : Formats validés.
- **Dépendances** : 2.1.
- **Outils/VSIX** : Tableur, VSCode.
- **Persona/Mode** : Documentation Writer.

#### 2.2. Développement des scripts de génération/validation

##### 2.2.1. Génération des mappings spécifiques
- **Objectif** : Générer les fichiers de mapping pour chaque extension.
- **Input** : YAML central.
- **Output** : Fichiers de mapping.
- **Critères** : Génération automatisée.
- **Dépendances** : 2.1.1.
- **Outils/VSIX** : Node.js, Python.
- **Persona/Mode** : Code.
- **Exemple** :  
  - Script : `node generate-roomodes-mapping.js`

##### 2.2.1.1. Validation automatique de la cohérence
- **Objectif** : Vérifier l’exhaustivité et la cohérence.
- **Input** : Fichiers de mapping.
- **Output** : Rapport de validation.
- **Critères** : 100% tests OK.
- **Dépendances** : 2.2.1.
- **Outils/VSIX** : Jest, Pytest.
- **Persona/Mode** : Jest Test Engineer.
- **Exemple** :  
  - Script : `pytest test_mapping.py`

#### 2.3. Intégration CI/CD

##### 2.3.1. Ajout des scripts à la CI/CD
- **Objectif** : Automatiser la validation et la génération.
- **Input** : Scripts, tests.
- **Output** : Pipeline CI/CD actif.
- **Critères** : Pipeline opérationnel.
- **Dépendances** : 2.2.1.1.
- **Outils/VSIX** : GitHub Actions, GitLab CI.
- **Persona/Mode** : DevOps.
- **Exemple** :  
  - Fichier : `.github/workflows/sync-modes.yml`

---

### 3. Gouvernance et processus

#### 3.1. Constitution du comité multi-extensions

##### 3.1.1. Désignation des représentants
- **Objectif** : Identifier un référent par extension.
- **Input** : Liste extensions.
- **Output** : Comité constitué.
- **Critères** : 100% extensions représentées.
- **Dépendances** : Aucun.
- **Outils/VSIX** : Tableur, Markdown.
- **Persona/Mode** : Orchestrator.

#### 3.2. Définition du processus de proposition/validation

##### 3.2.1. Rédaction du process PR/RFC/vote
- **Objectif** : Formaliser le workflow de validation.
- **Input** : Exemples existants, besoins comité.
- **Output** : Document de process.
- **Critères** : Process validé, publié.
- **Dépendances** : 3.1.1.
- **Outils/VSIX** : Markdown, VSCode.
- **Persona/Mode** : Orchestrator.
- **Exemple** :  
  - User story : « En tant que membre du comité, je veux valider chaque évolution via PR/RFC. »

#### 3.3. Historisation et audit

##### 3.3.1. Mise en place de l’historisation automatisée
- **Objectif** : Tracer chaque évolution du référentiel.
- **Input** : Commits, PR.
- **Output** : Historique accessible.
- **Critères** : Historique complet.
- **Dépendances** : 3.2.1.
- **Outils/VSIX** : Git, scripts d’audit.
- **Persona/Mode** : Security Reviewer.

##### 3.3.1.1. Audit périodique automatisé
- **Objectif** : Détecter les divergences, générer des alertes.
- **Input** : Historique, référentiel.
- **Output** : Rapports d’audit, alertes.
- **Critères** : Alertes fonctionnelles.
- **Dépendances** : 3.3.1.
- **Outils/VSIX** : Node.js, Python.
- **Persona/Mode** : Security Reviewer.
- **Exemple** :  
  - Script : `python audit-mapping.py`

---

### 4. Documentation et traçabilité

#### 4.1. Rédaction de la documentation utilisateur et technique

##### 4.1.1. Génération automatique à partir du YAML
- **Objectif** : Générer docs à jour depuis le référentiel.
- **Input** : YAML central.
- **Output** : Documentation générée.
- **Critères** : Docs publiées, traçabilité assurée.
- **Dépendances** : 1.3.
- **Outils/VSIX** : Script Node.js/Python, VSCode.
- **Persona/Mode** : Documentation Writer.
- **Exemple** :  
  - Script : `node generate-docs.js`

##### 4.1.1.1. Ajout systématique des liens vers plans existants
- **Objectif** : Garantir la traçabilité transverse.
- **Input** : Plans existants.
- **Output** : Liens intégrés.
- **Critères** : 100% des docs référencent les plans.
- **Dépendances** : 4.1.1.
- **Outils/VSIX** : Markdown, VSCode.
- **Persona/Mode** : Documentation Writer.

---

## 3. Exemples concrets (tickets, user stories, scripts, commandes)

- **Ticket** : « Développer le script de génération des mappings Roomodes »
  - Input : YAML central
  - Output : `roomodes-mapping.json`
  - Commande : `node generate-roomodes-mapping.js`
  - Critère : Fichier généré, validé par test

- **User story** :  
  « En tant que Security Reviewer, je veux auditer automatiquement les divergences de mapping pour garantir la cohérence transverse. »

- **Script** :  
  `python audit-mapping.py` — Génère un rapport d’audit et des alertes en cas de divergence.

---

## 4. Tableau de synthèse hiérarchique

| Niv. | Action | Responsable | Input | Output | Critère | Dépendances | Outils/VSIX | Lien plan |
|------|--------|-------------|-------|--------|---------|-------------|-------------|-----------|
| 1 | Définir schéma YAML | Documentation Writer | Analyse besoins | Schéma validé | Validation comité | - | VSCode, YAML Linter | v105b:58 |
| 1.1 | Recenser attributs | Project Research | Inventaire | Liste attributs | Exhaustivité | 1 | Tableur | - |
| 1.1.1 | Valider attributs | Orchestrator | Liste attributs | Validation | Accord comité | 1.1 | Markdown | - |
| 1.2 | Recenser modes | Code, Project Research | Code source | Inventaire | 100% recensé | 1.1.1 | Script Node.js | - |
| 1.2.1 | Dédoublonnage | Documentation Writer | Inventaire | Liste consolidée | Zéro doublon | 1.2 | Script Python | - |
| 1.3 | Rédiger YAML | Documentation Writer | Schéma, liste | YAML versionné | YAML validé | 1.2.1 | Git | - |
| 2 | Spécifier sync | Code, DevOps | Schéma, plans | Specs sync | Specs validées | 1.3 | Markdown | v105b:65 |
| 2.1 | Définir formats | Documentation Writer | Docs ext. | Specs formats | Formats validés | 2 | Tableur | - |
| 2.2 | Générer mappings | Code | YAML | Fichiers mapping | Génération auto | 2.1 | Node.js | - |
| 2.2.1 | Valider mapping | Jest Test Engineer | Fichiers mapping | Rapport tests | 100% OK | 2.2 | Jest | - |
| 2.3 | CI/CD | DevOps | Scripts, tests | Pipeline | Pipeline actif | 2.2.1 | GitHub Actions | - |
| 3 | Comité | Orchestrator | Liste ext. | Comité | 100% représenté | - | Tableur | - |
| 3.1 | Process PR/RFC | Orchestrator | Exemples | Doc process | Process publié | 3 | Markdown | - |
| 3.2 | Historisation | Security Reviewer | Commits | Historique | Historique complet | 3.1 | Git | - |
| 3.2.1 | Audit auto | Security Reviewer | Historique | Rapports, alertes | Alertes fonctionnelles | 3.2 | Python | - |
| 4 | Docs générées | Documentation Writer | YAML | Docs publiées | Traçabilité | 1.3 | Node.js | - |
| 4.1 | Liens plans | Documentation Writer | Plans existants | Liens intégrés | 100% docs référencées | 4 | Markdown | - |

---

## 5. Liens vers plans et audits existants

- [`plan-dev-v105`](projet/roadmaps/plans/consolidated/plan-dev-v105-gestion-personas-modes-multi-ext.md:1)
- [`plan-dev-v105b`](projet/roadmaps/plans/consolidated/plan-dev-v105b-gestion-personas-modes-multi-ext.md:1)
- [`projet/roadmaps/plans/audits/`](projet/roadmaps/plans/audits:1)