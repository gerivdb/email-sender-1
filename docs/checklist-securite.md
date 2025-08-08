ur# Checklist sécurité par mode

## Introduction
Objectifs et portée de la checklist sécurité.

## Mode Code
- Contrôle des accès :
  - Vérifier les permissions sur chaque module.
  - Exemple : audit des ACL avant chaque release.
- Validation des entrées :
  - Utiliser des schémas de validation (ex : JSON Schema).
  - Exemple : tests unitaires sur les entrées utilisateur.
- Revue de dépendances :
  - Scanner les dépendances avec Snyk/SonarQube.
  - Lien : [docs/devsecops-rituels.md](docs/devsecops-rituels.md:1)

## Mode Architect
- Analyse des risques :
  - Cartographier les menaces et vulnérabilités.
  - Exemple : matrice de risques pour chaque manager.
- Conformité réglementaire :
  - Vérifier l’alignement RGPD, ISO, etc.
  - Lien : [docs/modes-gouvernance.md](docs/modes-gouvernance.md:1)
- Documentation des flux :
  - Décrire les flux de données et points d’exposition.
  - Exemple : diagramme mermaid des échanges inter-modules.

## Mode Debug
- Masquage des données sensibles :
  - Appliquer des fonctions de hash ou d’anonymisation.
  - Exemple : suppression des tokens dans les logs.
- Journalisation sécurisée :
  - Utiliser des formats standard, limiter la rétention.
  - Lien : [docs/devsecops-rituels.md](docs/devsecops-rituels.md:1)
- Gestion des erreurs :
  - Centraliser la gestion via ErrorManager.
  - Exemple : rapport d’erreur structuré, audit mensuel.

## Mode Orchestrator
- Isolation des processus :
  - Séparer les workflows critiques, limiter les accès croisés.
  - Exemple : sandbox pour les tâches sensibles.
- Monitoring centralisé :
  - Agréger les métriques et alertes via MonitoringManager.
  - Lien : [docs/modes-gouvernance.md](docs/modes-gouvernance.md:1)
- Audit des transitions :
  - Tracer chaque changement de mode, documenter les arbitrages.
  - Exemple : log des transitions dans .govpolicy.

## Mode Ask
- Protection des données utilisateur :
  - Chiffrer les échanges, anonymiser les logs.
  - Exemple : suppression des identifiants dans les réponses.
- Limitation des permissions :
  - Restreindre les accès aux fonctions critiques.
  - Lien : [docs/principes-modes.md](docs/principes-modes.md:1)
- Traçabilité des requêtes :
  - Journaliser les demandes et réponses, conserver l’historique.
  - Exemple : audit trimestriel des logs AskManager.

## Conclusion
La checklist sécurité doit être appliquée à chaque mode et revue à chaque release.
Pour chaque critère, documenter les écarts et référencer les politiques associées pour garantir la conformité et la traçabilité.