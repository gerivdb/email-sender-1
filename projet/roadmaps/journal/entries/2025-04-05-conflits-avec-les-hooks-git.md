---
date: 2025-04-05
title: Conflits avec les hooks Git
tags: []
related: []
---

## Conflits avec les hooks Git

- **Problème identifié** : Erreur d'accès au fichier pre-commit pendant le processus de commit
  ```
  Set-Content : Le processus ne peut pas accéder au fichier '.git/hooks/pre-commit', car il est en cours d'utilisation par un autre processus.
  ```
- **Cause** : Le script auto-organize-silent.ps1 tente de modifier le hook pre-commit pendant que Git l'utilise
- **Solutions** :
  - Exécuter les scripts d'organisation avant de lancer la commande de commit
  - Modifier le script pour vérifier si le fichier est déjà en cours d'utilisation
  - Implémenter un mécanisme de verrouillage pour éviter les accès concurrents

###

