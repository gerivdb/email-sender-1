# Plan de développement v114 — Correctif et fiabilisation de l’intégration terminal Roo Code VS Code

---

## Phase 1 : Analyse du problème d’intégration

- **Objectif** : Recenser et qualifier les difficultés d’intégration du terminal Roo Code dans VS Code (toutes versions).
- **Livrables** : `rapport-integration-terminal-roo-code.md` (source), synthèse des causes racines.
- **Dépendances** : Logs d’installation, documentation Roo Code, feedback utilisateur.
- **Risques** : Variabilité selon version VS Code, shell, OS.
- **Outils mobilisés** : Analyse documentaire, feedback utilisateur, tests manuels.
- **Tâches** :
  - [ ] Collecter les logs et retours d’expérience sur l’intégration terminal Roo Code.
  - [ ] Identifier les causes d’échec (héritage env, shell, version VS Code…).
  - [ ] Documenter les cas d’incompatibilité et les contextes à risque.
- **Commandes** :
  - `echo $SHELL`
  - `code --version`
- **Critères de validation** :
  - Causes racines identifiées et documentées.
  - Rapport d’analyse validé par un pair.
- **Rollback** :
  - Sauvegarde du rapport initial.
- **Questions ouvertes** :
  - Quels environnements sont les plus touchés ?
- **Auto-critique** :
  - Limite : analyse dépendante des retours utilisateurs.

---

## Phase 2 : Définition et documentation des solutions correctives

- **Objectif** : Formaliser les solutions et procédures pour fiabiliser l’intégration.
- **Livrables** : Documentation structurée des solutions, checklists de validation.
- **Dépendances** : Rapport phase 1, documentation officielle VS Code/Roo Code.
- **Risques** : Solutions non universelles, contournements temporaires.
- **Outils mobilisés** : Documentation, scripts shell/PowerShell, guides Roo Code.
- **Tâches** :
  - [ ] Rédiger les solutions immédiates (paramétrage, redémarrage, shell).
  - [ ] Détailler les procédures pour chaque OS/shell (bash, zsh, PowerShell, WSL).
  - [ ] Proposer des contournements d’urgence et des tests de validation.
  - [ ] Centraliser les liens et références utiles.
- **Commandes** :
  - Modifier `terminal.integrated.inheritEnv` dans VS Code.
  - Ajouter la ligne d’intégration shell adaptée.
- **Critères de validation** :
  - Toutes les solutions sont testées et validées sur au moins 2 environnements.
  - Documentation accessible et claire.
- **Rollback** :
  - Restauration des paramètres VS Code/shell initiaux.
- **Questions ouvertes** :
  - Faut-il automatiser la détection du shell ?
- **Auto-critique** :
  - Limite : certains workarounds peuvent être obsolètes selon les versions futures.

---

## Phase 3 : Procédure de validation et diffusion

- **Objectif** : Garantir la reproductibilité et la traçabilité des correctifs.
- **Livrables** : Checklist de validation, rapport de tests croisés, mise à jour documentation centrale.
- **Dépendances** : Documentation phase 2, accès à plusieurs environnements.
- **Risques** : Non-reproductibilité sur certains OS, oubli de mise à jour de la doc.
- **Outils mobilisés** : Scripts de test, feedback utilisateur, CI/CD doc.
- **Tâches** :
  - [ ] Appliquer les réglages recommandés sur différents environnements.
  - [ ] Redémarrer VS Code et tous les terminaux.
  - [ ] Tester l’exécution de commandes Roo Code simples et complexes.
  - [ ] Documenter les résultats et ajuster la procédure si besoin.
  - [ ] Mettre à jour la documentation centrale `.github/docs/roo/rapport-integration-terminal-roo-code.md`.
- **Commandes** :
  - `echo "test"`
  - `ls -la`
- **Critères de validation** :
  - 100 % des tests passent sur les environnements cibles.
  - Documentation centrale à jour.
- **Rollback** :
  - Restauration des paramètres initiaux, suppression des modifications non validées.
- **Questions ouvertes** :
  - Peut-on automatiser la validation via CI ?
- **Auto-critique** :
  - Limite : validation manuelle nécessaire sur certains OS.

---

## Phase 4 : Orchestration, CI/CD et traçabilité

- **Objectif** : Intégrer la validation et la documentation dans la roadmap et le pipeline documentaire.
- **Livrables** : Plan intégré dans la roadmap, badge de validation, logs de diffusion.
- **Dépendances** : Phases précédentes, accès CI/CD.
- **Risques** : Oubli d’intégration, documentation non synchronisée.
- **Outils mobilisés** : RoadmapManager, scripts CI, logs.
- **Tâches** :
  - [ ] Ajouter le plan dans la roadmap consolidée.
  - [ ] Générer un badge de validation pour la documentation.
  - [ ] Archiver les logs et rapports de validation.
  - [ ] Assurer la traçabilité croisée avec [`rapport-integration-terminal-roo-code.md`](.github/docs/roo/rapport-integration-terminal-roo-code.md:1).
- **Critères de validation** :
  - Plan visible dans la roadmap.
  - Badge de validation affiché.
  - Traçabilité documentaire assurée.
- **Rollback** :
  - Suppression du plan de la roadmap si invalidation.
- **Questions ouvertes** :
  - Faut-il prévoir une veille sur les évolutions VS Code/Roo Code ?
- **Auto-critique** :
  - Limite : dépendance à la veille documentaire.

---

## Fichiers attendus

- `projet/roadmaps/plans/consolidated/plan-dev-v114-correctif-roo-integ.md` (ce plan)
- `.github/docs/roo/rapport-integration-terminal-roo-code.md` (rapport détaillé)
- Checklists de validation, logs de tests, scripts éventuels

---

## Critères de validation globaux

- Plan structuré, séquencé, actionnable et traçable
- Documentation centrale à jour et référencée
- Validation croisée sur plusieurs environnements
- Rollback documenté et automatisable

---

## Liens et références

- [`rapport-integration-terminal-roo-code.md`](.github/docs/roo/rapport-integration-terminal-roo-code.md:1)
- [Fiche mode plandev-engineer](.roo/rules/rules.md:fiche-mode-plandev-engineer)
- [AGENTS.md](AGENTS.md)
- [workflows-matrix.md](.roo/rules/workflows-matrix.md)
- [plan-dev-v107-rules-roo.md](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
