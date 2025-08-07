# Procédure DevSecOps

## Introduction
Objectifs et périmètre de la démarche DevSecOps.

## Rituels quotidiens
- Revue de code : validation croisée, application des principes DRY/KISS/SOLID.
- Analyse de sécurité : scan automatique des vulnérabilités, vérification des accès.
- Intégration continue : pipeline CI/CD avec tests unitaires et sécurité.

## Rituels hebdomadaires
- Audit de dépendances : vérification des versions, suppression des modules obsolètes.
- Tests de résilience : simulation d’incidents, analyse des logs d’erreur.
- Mise à jour des outils : upgrade des scanners, documentation des changements.

## Rituels mensuels
- Simulation d’incident : test de restauration, analyse des procédures de rollback.
- Revue des politiques de sécurité : mise à jour des règles, validation des accès critiques.
- Formation et sensibilisation : ateliers pratiques, diffusion des bonnes pratiques.

## Outils et pratiques recommandés
- Liste des outils :
  - SonarQube (analyse code/sécurité)
  - Snyk (audit dépendances)
  - GitHub Actions (CI/CD)
  - Vault (gestion des secrets)
- Bonnes pratiques :
  - Documentation systématique des incidents
  - Utilisation de branches dédiées pour les correctifs
  - Application stricte des checklists sécurité ([docs/checklist-securite.md](docs/checklist-securite.md:1))

## Conclusion
La démarche DevSecOps repose sur la régularité des rituels, l’automatisation des contrôles et la traçabilité des actions.
Pour chaque rituel, documenter les écarts et proposer des axes d’amélioration continue.