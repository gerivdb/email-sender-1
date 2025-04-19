# Convertisseur de Roadmap

Ce dossier contient des scripts pour convertir une roadmap existante vers le nouveau format de template.

## Fichiers

- `RoadmapConverter.psm1` : Module PowerShell contenant les fonctions de conversion
- `Convert-Roadmap.ps1` : Script principal pour convertir une roadmap
- `Test-RoadmapConverter.ps1` : Script de test pour vérifier le fonctionnement du convertisseur
- `README.md` : Ce fichier

## Utilisation

### Conversion d'une roadmap

Pour convertir une roadmap existante vers le nouveau format de template, utilisez le script `Convert-Roadmap.ps1` :

```powershell
.\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"
```

Paramètres :
- `SourcePath` : Chemin vers la roadmap existante
- `TemplatePath` : Chemin vers le fichier de template
- `OutputPath` : Chemin où la nouvelle roadmap sera enregistrée

### Test du convertisseur

Pour tester le fonctionnement du convertisseur, utilisez le script `Test-RoadmapConverter.ps1` :

```powershell
.\Test-RoadmapConverter.ps1
```

Ce script exécute une série de tests pour vérifier que le convertisseur fonctionne correctement.

## Fonctionnement

Le convertisseur fonctionne en quatre étapes :

1. **Analyse** : Le script analyse la roadmap existante et extrait sa structure (sections, sous-sections, tâches, etc.)
2. **Extraction** : Le script extrait la structure du template
3. **Transformation** : Le script transforme la structure de la roadmap selon le format du template
4. **Génération** : Le script génère la nouvelle roadmap à partir de la structure transformée

## Personnalisation

Si vous souhaitez personnaliser le comportement du convertisseur, vous pouvez modifier les fonctions dans le module `RoadmapConverter.psm1` :

- `Parse-ExistingRoadmap` : Analyse une roadmap existante et extrait sa structure
- `Get-TemplateStructure` : Extrait la structure du template
- `Transform-RoadmapStructure` : Transforme la structure de la roadmap selon le template
- `Generate-NewRoadmap` : Génère une nouvelle roadmap à partir du contenu transformé

## Limitations

- Le convertisseur suppose que la roadmap existante suit une structure hiérarchique standard (titres de niveau 1 à 6)
- Certaines informations peuvent être perdues ou simplifiées lors de la conversion
- Les sections complexes ou non standard peuvent ne pas être correctement converties

## Dépannage

Si vous rencontrez des problèmes lors de l'utilisation du convertisseur, vérifiez les points suivants :

1. Assurez-vous que les fichiers source et template existent et sont accessibles
2. Vérifiez que la roadmap existante suit une structure hiérarchique standard
3. Exécutez le script de test pour identifier les problèmes potentiels
4. Consultez les messages d'erreur pour obtenir des informations sur la nature du problème

## Contribution

Si vous souhaitez améliorer le convertisseur, n'hésitez pas à proposer des modifications. Voici quelques idées d'amélioration :

- Ajouter une interface utilisateur graphique
- Améliorer la détection des sections non standard
- Ajouter des options de personnalisation pour la conversion
- Implémenter une validation plus stricte de la roadmap générée

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
