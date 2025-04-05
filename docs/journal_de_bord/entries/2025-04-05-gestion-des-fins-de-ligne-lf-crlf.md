---
date: 2025-04-05
title: Gestion des fins de ligne (LF/CRLF)
tags: []
related: []
---

## Gestion des fins de ligne (LF/CRLF)
- **Problème identifié** : Nombreux avertissements sur les fins de ligne lors du commit
  ```
  warning: in the working copy of 'file.md', LF will be replaced by CRLF the next time Git touches it
  ```
- **Cause** : Différence de gestion des fins de ligne entre les systèmes d'exploitation
- **Solutions** :
  - Configurer Git avec `git config --global core.autocrlf true` (pour Windows)
  - Ajouter un fichier .gitattributes pour définir explicitement la gestion des fins de ligne
  - Standardiser l'environnement de développement pour éviter les problèmes de compatibilité

##
