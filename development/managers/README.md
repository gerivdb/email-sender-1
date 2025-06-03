# Gestionnaires

Ce rÃ©pertoire contient tous les gestionnaires du projet.

## Structure

Chaque gestionnaire est organisÃ© selon la structure suivante :

- <gestionnaire>/config : Fichiers de configuration spÃ©cifiques au gestionnaire
- <gestionnaire>/scripts : Scripts PowerShell du gestionnaire
- <gestionnaire>/modules : Modules PowerShell du gestionnaire
- <gestionnaire>/tests : Tests unitaires et d'intÃ©gration du gestionnaire

## Gestionnaires disponibles

- integrated-manager : Gestionnaire intÃ©grÃ© qui coordonne tous les autres gestionnaires
- mode-manager : Gestionnaire des modes opÃ©rationnels
- roadmap-manager : Gestionnaire de la roadmap
- mcp-manager : Gestionnaire MCP
- script-manager : Gestionnaire de scripts
- dependency-manager : Gestionnaire de dépendances Go
- error-manager : Gestionnaire d'erreurs
- n8n-manager : Gestionnaire n8n

## Configuration

Les fichiers de configuration des gestionnaires sont centralisÃ©s dans le rÃ©pertoire projet/config/managers.
