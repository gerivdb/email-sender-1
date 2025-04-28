# Configuration Augment

Ce dossier contient les fichiers de configuration pour Augment, l'outil d'IA utilisé pour le développement assisté.

## Fichiers

### augment-optimized-settings.json

Ce fichier contient les paramètres optimisés pour Augment, notamment :

- Limites de taille d'entrée
- Paramètres de performance
- Configuration des modes opérationnels
- Autres réglages spécifiques à Augment

## Utilisation

Pour utiliser ces paramètres avec Augment, vous pouvez :

1. **Référencer ce fichier directement** dans les commandes Augment
2. **Créer un lien symbolique** vers ce fichier depuis la racine du projet si nécessaire

## Note importante

Si Augment ne fonctionne pas correctement, il est possible qu'il recherche ce fichier à la racine du projet. Pour cette raison, une copie du fichier est maintenue à la racine du projet.

Pour synchroniser les fichiers après une modification, utilisez le script suivant :

```powershell
# Mettre à jour le fichier à la racine depuis le fichier dans development
.\development\scripts\maintenance\augment\sync-augment-settings.ps1 -Direction ToRoot

# OU

# Mettre à jour le fichier dans development depuis le fichier à la racine
.\development\scripts\maintenance\augment\sync-augment-settings.ps1 -Direction FromRoot
```

## Maintenance

Lorsque vous mettez à jour les paramètres d'Augment, assurez-vous de mettre à jour ce fichier plutôt que d'en créer un nouveau à la racine du projet.
