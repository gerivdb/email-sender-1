# Changements de chemins et reconstruction du projet

## Contexte

Suite à des problèmes avec les chemins contenant des accents français et des espaces, tous les chemins du projet ont été modifiés pour utiliser des underscores à la place. Plus récemment, le chemin a été simplifié davantage :
- `D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1` (original avec espaces et accents)
- `D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1` (première normalisation)
- `D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1` (simplification actuelle)

Ce document explique les changements effectués et comment le projet a été rebâti.

## Changements effectués

1. **Mise à jour des chemins dans les fichiers de configuration**
   - Le fichier `mcp-git-ingest-config.json` a été mis à jour pour utiliser le nouveau chemin avec underscores
   - Les scripts qui utilisent des chemins relatifs n'ont pas eu besoin d'être modifiés

2. **Vérification des fichiers de workflow n8n**
   - Les workflows n8n ont été vérifiés pour s'assurer qu'ils sont correctement encodés et configurés

3. **Organisation des fichiers selon la structure définie**
   - Le script `create-folders.ps1` a été exécuté pour créer la structure de dossiers
   - Le script `organize-n8n-files.ps1` a été exécuté pour organiser les fichiers n8n

4. **Vérification des scripts de démarrage**
   - Les scripts de démarrage ont été vérifiés pour s'assurer qu'ils sont correctement configurés

## Structure du projet

La structure du projet est maintenant organisée comme suit :

```
├── workflows/            # Workflows n8n finaux
│   ├── core/             # Workflows principaux
│   ├── config/           # Workflows de configuration
│   ├── phases/           # Workflows par phase
│   └── testing/          # Workflows de test
├── credentials/          # Informations d'identification
├── config/               # Fichiers de configuration
├── mcp/                  # Configurations MCP
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n (développement)
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── maintenance/      # Scripts de maintenance
│   ├── setup/            # Scripts d'installation
│   └── utils/            # Scripts utilitaires
├── logs/                 # Fichiers de logs
├── docs/                 # Documentation
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
```

## Comment démarrer le projet

1. **Démarrer n8n avec les MCP configurés**
   ```
   .\tools\start-n8n-mcp.cmd
   ```

2. **Configurer les MCP**
   ```
   .\scripts\setup\configure-n8n-mcp.ps1
   .\scripts\setup\configure-mcp-git-ingest.ps1
   ```

3. **Organiser les fichiers**
   ```
   .\scripts\maintenance\organize-n8n-files.ps1
   ```

## Problèmes connus

- Certains fichiers peuvent encore contenir des références aux anciens chemins
- Les scripts qui utilisent des chemins absolus peuvent nécessiter des mises à jour supplémentaires

## Prochaines étapes

- Tester tous les workflows n8n pour s'assurer qu'ils fonctionnent correctement
- Mettre à jour les scripts qui utilisent des chemins absolus
- Configurer l'automatisation pour maintenir la structure du projet
