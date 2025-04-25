# Templates de maintenance Hygen

Ce répertoire contient des templates Hygen pour générer des scripts de maintenance pour le projet.

## Structure

- **organize/** - Templates pour les scripts d'organisation
- **cleanup/** - Templates pour les scripts de nettoyage
- **migrate/** - Templates pour les scripts de migration
- **init/** - Templates pour initialiser la structure de maintenance
- **docs/** - Templates pour la documentation de maintenance

## Utilisation

### Initialisation de la structure de maintenance

```bash
hygen maintenance init
```

Cette commande génère un script PowerShell qui crée la structure de dossiers nécessaire pour la maintenance.

### Génération de scripts d'organisation

```bash
hygen maintenance organize
```

Cette commande génère un script PowerShell pour organiser les fichiers et dossiers selon une structure prédéfinie.

### Génération de scripts de nettoyage

```bash
hygen maintenance cleanup
```

Cette commande génère un script PowerShell pour nettoyer les fichiers inutiles dans un répertoire.

### Génération de scripts de migration

```bash
hygen maintenance migrate
```

Cette commande génère un script PowerShell pour migrer des fichiers d'un répertoire à un autre.

## Personnalisation

Vous pouvez personnaliser les templates en modifiant les fichiers `.ejs.t` dans chaque sous-répertoire.

## Bonnes pratiques

1. Toujours exécuter les scripts générés en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
4. Tester les scripts dans un environnement de développement avant de les utiliser en production
