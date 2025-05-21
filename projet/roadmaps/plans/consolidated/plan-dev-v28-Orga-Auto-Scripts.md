---
to: "plan-dev/plan-dev-v28.md"
---

# Plan Dev: Organisation Automatisée des Scripts

Date de création : 2025-05-21  
Auteur : À compléter

## Objectif

Mettre en place une organisation automatisée des scripts du dépôt, combinant Hygen pour la génération de structure et Watchdog pour le tri automatique, tout en gérant les exceptions (fichiers critiques, scripts de tri, etc.).

## Étapes principales

- [ ] Définir les besoins et exceptions
{
  // Snippets individuels
  "DEVR": {
    "prefix": "devr",
    "body": [
      "DEV-R NEXT"
    ],
    "description": "Passe à la tâche suivante en mode développement séquentiel. Permet d’avancer d’une étape dans la séquence de développement, en suivant la logique du mode DEV-R (implémentation séquentielle des tâches)."
  },
  "GIT ACP": {
    "prefix": "gitacp",
    "body": [
      "git add . && git commit -m \"[${1:MODE}] ${2:message}\" && git push --no-verify"
    ],
    "description": "Add, commit, push rapide. Exécute en une seule commande l’ajout, le commit (avec préfixe de mode personnalisable), et le push des modifications sur le dépôt Git, pour accélérer le cycle de versionning. Utilise des placeholders pour personnaliser le mode et le message de commit."
  },
  // Snippets de combinaisons (flow/combo)
  "FLOW DEV": {
    "prefix": "flowdev",
    "body": [
      "GRAN → DEV-R → TEST → DEBUG → GIT ACP"
    ],
    "description": "Cycle de développement complet. Insère la séquence standard de développement, enchaînant la granularisation, le développement, les tests, le debug, puis le commit/push Git. Sert de référence ou de guide pour automatiser ce workflow."
  },
  "COMBO DEV-R,TEST,DEBUG": {
    "prefix": "combodev",
    "body": [
      "COMBO DEV-R,TEST,DEBUG"
    ],
    "description": "Enchaîne DEV-R, TEST, puis DEBUG. Permet de lancer une séquence automatisée où l’on développe, teste, puis débogue sans interruption, pour gagner du temps sur les cycles courts."
  },
  "FLOW HOTFIX": {
    "prefix": "flowhotfix",
    "body": [
      "DEBUG → TEST FAST → GIT ACP → GIT SYNC"
    ],
    "description": "Correction d'urgence. Insère la séquence d’intervention rapide pour corriger un bug critique : debug, tests rapides, commit/push, puis synchronisation avec le dépôt distant."
  }
}
{
  // Snippets individuels
  "DEVR": {
    "prefix": "devr",
    "body": [
      "DEV-R NEXT"
    ],
    "description": "Passe à la tâche suivante en mode développement séquentiel. Permet d’avancer d’une étape dans la séquence de développement, en suivant la logique du mode DEV-R (implémentation séquentielle des tâches)."
  },
  "GIT ACP": {
    "prefix": "gitacp",
    "body": [
      "git add . && git commit -m \"[${1:MODE}] ${2:message}\" && git push --no-verify"
    ],
    "description": "Add, commit, push rapide. Exécute en une seule commande l’ajout, le commit (avec préfixe de mode personnalisable), et le push des modifications sur le dépôt Git, pour accélérer le cycle de versionning. Utilise des placeholders pour personnaliser le mode et le message de commit."
  },
  // Snippets de combinaisons (flow/combo)
  "FLOW DEV": {
    "prefix": "flowdev",
    "body": [
      "GRAN → DEV-R → TEST → DEBUG → GIT ACP"
    ],
    "description": "Cycle de développement complet. Insère la séquence standard de développement, enchaînant la granularisation, le développement, les tests, le debug, puis le commit/push Git. Sert de référence ou de guide pour automatiser ce workflow."
  },
  "COMBO DEV-R,TEST,DEBUG": {
    "prefix": "combodev",
    "body": [
      "COMBO DEV-R,TEST,DEBUG"
    ],
    "description": "Enchaîne DEV-R, TEST, puis DEBUG. Permet de lancer une séquence automatisée où l’on développe, teste, puis débogue sans interruption, pour gagner du temps sur les cycles courts."
  },
  "FLOW HOTFIX": {
    "prefix": "flowhotfix",
    "body": [
      "DEBUG → TEST FAST → GIT ACP → GIT SYNC"
    ],
    "description": "Correction d'urgence. Insère la séquence d’intervention rapide pour corriger un bug critique : debug, tests rapides, commit/push, puis synchronisation avec le dépôt distant."
  }
}
{
  // Snippets individuels
  "DEVR": {
    "prefix": "devr",
    "body": [
      "DEV-R NEXT"
    ],
    "description": "Passe à la tâche suivante en mode développement séquentiel. Permet d’avancer d’une étape dans la séquence de développement, en suivant la logique du mode DEV-R (implémentation séquentielle des tâches)."
  },
  "GIT ACP": {
    "prefix": "gitacp",
    "body": [
      "git add . && git commit -m \"[${1:MODE}] ${2:message}\" && git push --no-verify"
    ],
    "description": "Add, commit, push rapide. Exécute en une seule commande l’ajout, le commit (avec préfixe de mode personnalisable), et le push des modifications sur le dépôt Git, pour accélérer le cycle de versionning. Utilise des placeholders pour personnaliser le mode et le message de commit."
  },
  // Snippets de combinaisons (flow/combo)
  "FLOW DEV": {
    "prefix": "flowdev",
    "body": [
      "GRAN → DEV-R → TEST → DEBUG → GIT ACP"
    ],
    "description": "Cycle de développement complet. Insère la séquence standard de développement, enchaînant la granularisation, le développement, les tests, le debug, puis le commit/push Git. Sert de référence ou de guide pour automatiser ce workflow."
  },
  "COMBO DEV-R,TEST,DEBUG": {
    "prefix": "combodev",
    "body": [
      "COMBO DEV-R,TEST,DEBUG"
    ],
    "description": "Enchaîne DEV-R, TEST, puis DEBUG. Permet de lancer une séquence automatisée où l’on développe, teste, puis débogue sans interruption, pour gagner du temps sur les cycles courts."
  },
  "FLOW HOTFIX": {
    "prefix": "flowhotfix",
    "body": [
      "DEBUG → TEST FAST → GIT ACP → GIT SYNC"
    ],
    "description": "Correction d'urgence. Insère la séquence d’intervention rapide pour corriger un bug critique : debug, tests rapides, commit/push, puis synchronisation avec le dépôt distant."
  }
}
{
  // Snippets individuels
  "DEVR": {
    "prefix": "devr",
    "body": [
      "DEV-R NEXT"
    ],
    "description": "Passe à la tâche suivante en mode développement séquentiel. Permet d’avancer d’une étape dans la séquence de développement, en suivant la logique du mode DEV-R (implémentation séquentielle des tâches)."
  },
  "GIT ACP": {
    "prefix": "gitacp",
    "body": [
      "git add . && git commit -m \"[${1:MODE}] ${2:message}\" && git push --no-verify"
    ],
    "description": "Add, commit, push rapide. Exécute en une seule commande l’ajout, le commit (avec préfixe de mode personnalisable), et le push des modifications sur le dépôt Git, pour accélérer le cycle de versionning. Utilise des placeholders pour personnaliser le mode et le message de commit."
  },
  // Snippets de combinaisons (flow/combo)
  "FLOW DEV": {
    "prefix": "flowdev",
    "body": [
      "GRAN → DEV-R → TEST → DEBUG → GIT ACP"
    ],
    "description": "Cycle de développement complet. Insère la séquence standard de développement, enchaînant la granularisation, le développement, les tests, le debug, puis le commit/push Git. Sert de référence ou de guide pour automatiser ce workflow."
  },
  "COMBO DEV-R,TEST,DEBUG": {
    "prefix": "combodev",
    "body": [
      "COMBO DEV-R,TEST,DEBUG"
    ],
    "description": "Enchaîne DEV-R, TEST, puis DEBUG. Permet de lancer une séquence automatisée où l’on développe, teste, puis débogue sans interruption, pour gagner du temps sur les cycles courts."
  },
  "FLOW HOTFIX": {
    "prefix": "flowhotfix",
    "body": [
      "DEBUG → TEST FAST → GIT ACP → GIT SYNC"
    ],
    "description": "Correction d'urgence. Insère la séquence d’intervention rapide pour corriger un bug critique : debug, tests rapides, commit/push, puis synchronisation avec le dépôt distant."
  }
}
 - [ ] Lister les types de fichiers à trier
 - [ ] Définir la destination logique de chaque type de fichier
 - [ ] Identifier les fichiers/dossiers à ne jamais déplacer (ex: `.env`, `README.md`, scripts de tri, `.keep`)
 - [ ] Documenter les règles d’exception dans un fichier de configuration
- [ ] Créer les templates Hygen pour la structure et les fichiers `.keep`
 - [ ] Générer la structure de base du projet avec Hygen
 - [ ] Ajouter des templates pour chaque type de dossier
 - [ ] Inclure un fichier `.keep` dans chaque dossier à versionner
- [ ] Mettre en place le template de tri (`sort_template.json`)
 - [ ] Définir les patterns de fichiers et leurs destinations dans `sort_template.json`
 - [ ] Créer un fichier `sort_exceptions.json` listant les exceptions
- [ ] Développer le script de tri automatique avec gestion des exceptions
 - [ ] Écrire un script Python pour trier les fichiers selon les règles
 - [ ] Intégrer la gestion des exceptions dans le script
 - [ ] Tester le script manuellement sur différents cas
- [ ] Automatiser le tri avec Watchdog
 - [ ] Installer Watchdog
 - [ ] Configurer Watchdog pour surveiller le dossier `scripts`
 - [ ] Lancer le script de tri automatiquement à chaque ajout/modification
 - [ ] Gérer les logs et les erreurs
- [ ] Documenter l’ensemble du système et les bonnes pratiques
 - [ ] Documenter l’utilisation de Hygen pour générer la structure
 - [ ] Expliquer le fonctionnement du script de tri
 - [ ] Décrire la gestion des exceptions
 - [ ] Expliquer comment ajouter de nouveaux types de fichiers ou exceptions
- [ ] Tester et valider le workflow
 - [ ] Tester le workflow sur différents scénarios (ajout, déplacement, exception)
 - [ ] Valider la robustesse et la non-régression
- [ ] (Optionnel) Intégrer le tri dans la CI/CD
 - [ ] Ajouter des hooks ou jobs CI pour vérifier l’organisation du dépôt
 - [ ] Automatiser le tri lors des push/merge si pertinent

## Détails

- **Définir les besoins et exceptions** :
  - Lister tous les types de fichiers présents ou attendus dans le dossier `scripts`.
  - Définir pour chaque type la destination logique (ex: `python/`, `python/testing/`, `node/`, etc.).
  - Identifier les fichiers critiques à la racine ou nécessaires au fonctionnement du système.
  - Documenter ces règles dans un fichier de configuration (ex: `sort_exceptions.json`).

- **Créer les templates Hygen** :
  - Utiliser Hygen pour générer la structure initiale du projet.
  - Créer des templates pour chaque type de dossier, avec un fichier `.keep` pour assurer leur présence dans le versioning.
  - Prévoir la génération automatique de fichiers d’exception si besoin.

- **Mettre en place le template de tri** :
  - Rédiger un fichier `sort_template.json` décrivant les patterns de fichiers et leurs destinations.
  - Créer un fichier `sort_exceptions.json` listant tous les fichiers/dossiers à ne jamais déplacer.

- **Développer le script de tri automatique** :
  - Écrire un script Python qui lit les templates et trie les fichiers selon les règles définies.
  - Intégrer la gestion des exceptions pour ne jamais déplacer les fichiers listés.
  - Tester le script manuellement sur des cas simples et complexes.

- **Automatiser avec Watchdog** :
  - Installer la bibliothèque Watchdog.
  - Configurer Watchdog pour surveiller le dossier `scripts`.
  - Déclencher le script de tri à chaque ajout ou modification de fichier.
  - Gérer les logs, les erreurs et prévoir une notification en cas d’échec.

- **Documenter et diffuser les bonnes pratiques** :
  - Rédiger une documentation claire sur l’utilisation de Hygen et du script de tri.
  - Expliquer comment maintenir et faire évoluer les templates et les règles d’exception.
  - Décrire la procédure pour ajouter de nouveaux types de fichiers ou exceptions.

- **Tester et valider** :
  - Effectuer des tests sur différents scénarios (fichiers valides, exceptions, erreurs).
  - Vérifier la robustesse du système et l’absence de régressions.

- **Intégration continue (optionnel)** :
  - Ajouter des hooks ou jobs CI pour vérifier la bonne organisation du dépôt.
  - Automatiser le tri lors des push/merge si pertinent.

---

> Généré avec Hygen (plan-dev template)
