# Plan de développement v1.05d — Gouvernance & synchronisation ultra-granulaire des personas/modes multi-extensions VSIX

---

## PHASES — Matrice opérationnelle ultra-granulaire

Chaque niveau (phase, sous-phase, tâche, sous-tâche) intègre :
- Checklist détaillée
- Statut (⬜ À faire, 🟧 En cours, ✅ Terminé, ⛔ Bloqué)
- Responsable(s)
- Livrable(s) attendu(s)
- Dépendances
- Points de contrôle
- Validation
- Reporting

---

### Phase 1 — Définition du schéma cible

#### Bloc de pilotage phase :

- [ ] Phase 1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer, Project Research, Orchestrator
- **Livrable** : Spécification YAML, Table d’attributs, Exemples YAML
- **Dépendances** : Aucune
- **Points de contrôle** : Revue besoins, Table d’attributs, Exemples relus
- **Validation** : Accord comité, PV signé
- **Reporting** : CR réunion, Ticket validé, Log validation

##### 1.1 Définir le schéma cible du YAML central

- [ ] 1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Spécification YAML
- **Dépendances** : -
- **Points de contrôle** : Revue besoins
- **Validation** : Accord comité
- **Reporting** : CR réunion

###### 1.1.1 Recenser les attributs nécessaires

- [ ] 1.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Project Research
- **Livrable** : Liste attributs
- **Dépendances** : 1.1
- **Points de contrôle** : Table d’attributs
- **Validation** : Accord comité
- **Reporting** : Ticket validé

####### 1.1.1.1 Valider la liste des attributs

- [ ] 1.1.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : PV validation
- **Dépendances** : 1.1.1
- **Points de contrôle** : Revue multi-ext
- **Validation** : PV signé
- **Reporting** : Log validation

###### 1.1.2 Documenter les exemples d’utilisation

- [ ] 1.1.2 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Exemples YAML
- **Dépendances** : 1.1.1.1
- **Points de contrôle** : Exemples relus
- **Validation** : Accord comité
- **Reporting** : Ticket validé

##### 1.2 Recenser et consolider les modes/personas existants

- [ ] 1.2 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code, Project Research
- **Livrable** : Liste consolidée
- **Dépendances** : 1.1.2
- **Points de contrôle** : Extraction automatisée
- **Validation** : Liste validée
- **Reporting** : Rapport extraction

###### 1.2.1 Extraire automatiquement la liste par extension

- [ ] 1.2.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code
- **Livrable** : Fichiers inventaire
- **Dépendances** : 1.2
- **Points de contrôle** : Script extraction
- **Validation** : Rapport extraction
- **Reporting** : Log script

####### 1.2.1.1 Fusionner et dédoublonner les listes

- [ ] 1.2.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Liste consolidée
- **Dépendances** : 1.2.1
- **Points de contrôle** : Script fusion
- **Validation** : Accord comité
- **Reporting** : Rapport fusion

######## 1.2.1.1.1 Valider la liste consolidée

- [ ] 1.2.1.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : PV validation
- **Dépendances** : 1.2.1.1
- **Points de contrôle** : Revue multi-ext
- **Validation** : PV signé
- **Reporting** : Log validation

##### 1.3 Rédiger et versionner le YAML initial

- [ ] 1.3 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : personas-modes-mapping.yaml
- **Dépendances** : 1.2.1.1.1
- **Points de contrôle** : Commit Git
- **Validation** : Accord comité
- **Reporting** : Log commit

###### 1.3.1 Valider l’exhaustivité et la conformité du YAML

- [ ] 1.3.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : PV validation
- **Dépendances** : 1.3
- **Points de contrôle** : Revue YAML
- **Validation** : PV signé
- **Reporting** : Log validation

---

### Phase 2 — Synchronisation inter-extensions

#### Bloc de pilotage phase :

- [ ] Phase 2 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code, DevOps, Documentation Writer
- **Livrable** : Spécifications techniques, formats, scripts, mappings, pipeline CI/CD
- **Dépendances** : Phase 1
- **Points de contrôle** : Revue specs, Table formats, Tests unitaires, Génération automatisée
- **Validation** : Accord comité, 100% tests OK, Pipeline opérationnel
- **Reporting** : CR réunion, Ticket validé, Rapport tests, Log pipeline

##### 2.1 Spécifier les besoins de synchronisation inter-extensions

- [ ] 2.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code, DevOps
- **Livrable** : Spécifications techniques
- **Dépendances** : 1.3.1
- **Points de contrôle** : Revue specs
- **Validation** : Accord comité
- **Reporting** : CR réunion

###### 2.1.1 Définir les formats cibles par extension

- [ ] 2.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Spécifications formats
- **Dépendances** : 2.1
- **Points de contrôle** : Table formats
- **Validation** : Accord comité
- **Reporting** : Ticket validé

##### 2.2 Développer les scripts de génération et validation

- [ ] 2.2 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code
- **Livrable** : Scripts opérationnels
- **Dépendances** : 2.1.1
- **Points de contrôle** : Tests unitaires
- **Validation** : 100% tests OK
- **Reporting** : Rapport tests

###### 2.2.1 Générer automatiquement les mappings spécifiques

- [ ] 2.2.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Code
- **Livrable** : Fichiers mapping
- **Dépendances** : 2.2
- **Points de contrôle** : Génération automatisée
- **Validation** : Accord comité
- **Reporting** : Log génération

####### 2.2.1.1 Valider la cohérence et l’exhaustivité des mappings générés

- [ ] 2.2.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Jest Test Engineer
- **Livrable** : Rapport de validation
- **Dépendances** : 2.2.1
- **Points de contrôle** : Tests automatisés
- **Validation** : 100% OK
- **Reporting** : Rapport tests

##### 2.3 Intégrer la génération/validation dans la CI/CD

- [ ] 2.3 terminée
- **Statut** : ⬜ À faire
- **Responsable** : DevOps
- **Livrable** : Pipeline CI/CD actif
- **Dépendances** : 2.2.1.1
- **Points de contrôle** : Déploiement pipeline
- **Validation** : Pipeline opérationnel
- **Reporting** : Log pipeline

---

### Phase 3 — Gouvernance multi-extensions

#### Bloc de pilotage phase :

- [ ] Phase 3 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator, Security Reviewer
- **Livrable** : Liste représentants, document process, scripts d’audit, historique
- **Dépendances** : Phase 2
- **Points de contrôle** : Désignation référents, Workflow PR/RFC/vote, Historisation automatisée
- **Validation** : 100% extensions, Process validé, Historique complet
- **Reporting** : PV constitution, CR publication, Rapport audit

##### 3.1 Constituer le comité multi-extensions

- [ ] 3.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : Liste des représentants
- **Dépendances** : -
- **Points de contrôle** : Désignation référents
- **Validation** : 100% extensions
- **Reporting** : PV constitution

##### 3.2 Définir le processus de proposition/validation

- [ ] 3.2 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : Document de process
- **Dépendances** : 3.1
- **Points de contrôle** : Workflow PR/RFC/vote
- **Validation** : Process validé
- **Reporting** : CR publication

##### 3.3 Historisation et audit

- [ ] 3.3 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Security Reviewer
- **Livrable** : Scripts d’audit, historique
- **Dépendances** : 3.2
- **Points de contrôle** : Historisation automatisée
- **Validation** : Historique complet
- **Reporting** : Rapport audit

###### 3.3.1 Développer l’audit périodique automatisé

- [ ] 3.3.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Security Reviewer
- **Livrable** : Rapports d’audit, alertes
- **Dépendances** : 3.3
- **Points de contrôle** : Détection divergences
- **Validation** : Alertes fonctionnelles
- **Reporting** : Log audit

---

### Phase 4 — Documentation et publication

#### Bloc de pilotage phase :

- [ ] Phase 4 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Documentation générée, liens intégrés
- **Dépendances** : Phase 3
- **Points de contrôle** : Génération auto, Vérification liens
- **Validation** : Docs publiées, 100% docs référencées
- **Reporting** : Log publication, Rapport liens

##### 4.1 Générer et publier la documentation

- [ ] 4.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Documentation générée
- **Dépendances** : 1.3.1
- **Points de contrôle** : Génération auto
- **Validation** : Docs publiées
- **Reporting** : Log publication

###### 4.1.1 Ajouter systématiquement les liens vers les plans existants

- [ ] 4.1.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Documentation Writer
- **Livrable** : Liens intégrés
- **Dépendances** : 4.1
- **Points de contrôle** : Vérification liens
- **Validation** : 100% docs référencées
- **Reporting** : Rapport liens

---

### Phase 5 — Checklist globale et pilotage final

#### Bloc de pilotage phase :

- [ ] Phase 5 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : Checklist validée
- **Dépendances** : Toutes
- **Points de contrôle** : Revue finale
- **Validation** : Accord comité
- **Reporting** : CR synthèse

##### 5.1 Checklist globale (phases, tâches, sous-tâches)

- [ ] 5.1 terminée
- **Statut** : ⬜ À faire
- **Responsable** : Orchestrator
- **Livrable** : Checklist validée
- **Dépendances** : Toutes
- **Points de contrôle** : Revue finale
- **Validation** : Accord comité
- **Reporting** : CR synthèse

---

## Procédure d’intégration

1. **Sauvegarder l’ancien plan** :
   ```bash
   cp projet/roadmaps/plans/consolidated/plan-dev-v105c-gestion-personas-modes-multi-ext.md projet/roadmaps/plans/consolidated/plan-dev-v105c-gestion-personas-modes-multi-ext.md.bak
   ```
2. **Remplacer le contenu du plan par la matrice ci-dessus** (copier-coller ou script).
3. **Committer la modification** :
   ```bash
   git add projet/roadmaps/plans/consolidated/plan-dev-v105d-gestion-personas-modes-multi-ext.md
   git commit -m "Granularisation, pilotage manager et enrichissement du plan v105d"
   ```
4. **Vérifier la conformité et la traçabilité** (audit, liens, reporting).

---

## Diff synthétique v105c → v105d

- **Ajouts** :  
  - Bloc de pilotage détaillé à chaque niveau (phase, sous-phase, tâche, sous-tâche) : checklist, statut, responsable, livrable, dépendances, points de contrôle, validation, reporting.
  - Cases à cocher pour chaque action et chaque niveau.
  - Compatibilité renforcée pilotage manager/consolidated/audit.
- **Granularité** :  
  - Décomposition ultra-fine, chaque niveau explicitement pilotable.
  - Ajout de blocs de pilotage intermédiaires pour chaque sous-niveau.
- **Suppression** :  
  - Aucune suppression de contenu métier, uniquement remplacement du plan v105c par la version enrichie v105d.
- **Procédure** :  
  - Procédure d’intégration adaptée à la nouvelle version.
- **Historique** :  
  - Historique et annexes conservés dans les versions précédentes et le dépôt.

---

## Historique et annexes

*L’historique du fichier et les exemples concrets sont conservés dans les versions précédentes et les annexes du dépôt.*