# Outils de gestion de roadmap

Ce répertoire contient des outils pour gérer et mettre à jour les fichiers de roadmap du projet.

## Fonctionnalités

- **Vérification des tâches implémentées** : Vérifie si les tâches sélectionnées dans un fichier de roadmap sont implémentées et met à jour leur statut en cochant les cases correspondantes.
- **Interface utilisateur** : Interface graphique pour sélectionner un fichier de roadmap et les lignes à vérifier.
- **Intégration avec VS Code** : Commande et raccourci clavier pour exécuter la vérification de roadmap directement depuis VS Code.
- **Génération de rapports** : Option pour générer un rapport détaillé des tâches vérifiées.

## Scripts

- `Update-RoadmapStatus.ps1` : Script principal pour vérifier et mettre à jour le statut des tâches dans un fichier de roadmap.
- `Invoke-RoadmapCheck.ps1` : Interface utilisateur pour sélectionner un fichier de roadmap et les lignes à vérifier.
- `Test-RoadmapCheck.ps1` : Script de test pour vérifier le fonctionnement du mode CHECK.
- `Install-RoadmapCheckCommand.ps1` : Script d'installation pour ajouter une commande au menu contextuel de VS Code.

## Installation

1. Clonez ce répertoire dans votre projet.
2. Exécutez le script d'installation pour ajouter la commande au menu contextuel de VS Code :

```powershell
.\Install-RoadmapCheckCommand.ps1
```

## Utilisation

### Interface utilisateur

1. Exécutez le script `Invoke-RoadmapCheck.ps1` :

```powershell
.\Invoke-RoadmapCheck.ps1
```

2. Sélectionnez un fichier de roadmap dans la boîte de dialogue.
3. Sélectionnez les lignes à vérifier dans la liste (utilisez Ctrl ou Shift pour sélectionner plusieurs lignes).
4. Cliquez sur OK pour exécuter la vérification.

### Ligne de commande

Vous pouvez également exécuter le script `Update-RoadmapStatus.ps1` directement en ligne de commande :

```powershell
.\Update-RoadmapStatus.ps1 -RoadmapPath ".\Roadmap\roadmap_complete_converted.md" -LineNumbers 42,43,44
```

Ou en spécifiant les identifiants des tâches :

```powershell
.\Update-RoadmapStatus.ps1 -RoadmapPath ".\Roadmap\roadmap_complete_converted.md" -TaskIds "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2","2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3"
```

### VS Code

Après avoir installé la commande, vous pouvez l'exécuter dans VS Code en appuyant sur `Ctrl+Alt+C` ou en ouvrant la palette de commandes (`Ctrl+Shift+P`) et en tapant `roadmap.check`.

## Options

- `-VerifyOnly` : Vérifie seulement les tâches sans modifier le fichier de roadmap.
- `-GenerateReport` : Génère un rapport détaillé des tâches vérifiées.
- `-RoadmapDirectory` : Spécifie le répertoire contenant les fichiers de roadmap.

## Personnalisation

Vous pouvez personnaliser la logique de vérification des tâches en modifiant la fonction `Test-TaskImplementation` dans le script `Update-RoadmapStatus.ps1`. Par défaut, elle vérifie si la tâche contient certains mots-clés ou si son identifiant est dans une liste prédéfinie.

## Tests

Pour tester le fonctionnement du mode CHECK, exécutez le script de test :

```powershell
.\Test-RoadmapCheck.ps1
```

Ce script crée un fichier de roadmap de test, exécute le script de mise à jour de la roadmap, et vérifie que les tâches sont correctement mises à jour.

## Dépendances

- PowerShell 5.1 ou supérieur
- .NET Framework 4.5 ou supérieur (pour l'interface utilisateur)
- VS Code (pour l'intégration avec VS Code)

## Auteurs

- Roadmap Tools Team
