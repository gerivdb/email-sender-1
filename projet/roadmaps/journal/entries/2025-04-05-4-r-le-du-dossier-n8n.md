---
date: 2025-04-05
title: 4. Rôle du dossier .n8n
tags: []
related: []
---

## 4. Rôle du dossier .n8n

- Le dossier `.n8n` est crucial pour le fonctionnement de l'application et contient :
  - La base de données SQLite avec tous les workflows
  - Les credentials chiffrées
  - Les configurations locales
  - Les caches et données temporaires
- Ce dossier doit être inclus dans les sauvegardes mais pas nécessairement dans le contrôle de version
- La présence de ce dossier directement dans le projet facilite le développement et les tests

##

