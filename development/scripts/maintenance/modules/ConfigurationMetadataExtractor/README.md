# ConfigurationMetadataExtractor

Module PowerShell pour l'extraction des métadonnées de configuration.

## Description

Ce module fournit des fonctions pour analyser les fichiers de configuration, extraire leurs options, dépendances et contraintes. Il prend en charge plusieurs formats de configuration, notamment JSON, YAML, XML, INI et PSD1.

## Fonctionnalités

- Détection automatique du format de configuration
- Analyse de la structure des fichiers de configuration
- Extraction des options de configuration
- Détection des dépendances entre les options
- Analyse des contraintes sur les options
- Validation des valeurs par rapport aux contraintes
- Détection des dépendances circulaires

## Installation

1. Téléchargez le module dans un dossier de modules PowerShell
2. Importez le module avec `Import-Module ConfigurationMetadataExtractor`

## Prérequis

- PowerShell 5.1 ou supérieur
- Module PowerShell-Yaml (optionnel, pour le support YAML)

## Fonctions principales

### Get-ConfigurationFormat

Détecte le format d'un fichier de configuration.

```powershell
Get-ConfigurationFormat -Path "config.json"
Get-ConfigurationFormat -Content '{"key": "value"}'
```plaintext
### Get-ConfigurationStructure

Analyse la structure d'un fichier de configuration.

```powershell
Get-ConfigurationStructure -Path "config.json"
Get-ConfigurationStructure -Content '{"key": "value"}' -Format "JSON"
```plaintext
### Get-ConfigurationOptions

Détecte les options de configuration dans un fichier de configuration.

```powershell
Get-ConfigurationOptions -Path "config.json"
Get-ConfigurationOptions -Path "config.json" -IncludeValues -Flatten
```plaintext
### Get-ConfigurationDependencies

Extrait les dépendances d'un fichier de configuration.

```powershell
Get-ConfigurationDependencies -Path "config.json"
Get-ConfigurationDependencies -Path "config.json" -DetectionMode "All" -ExternalPaths "external.json"
```plaintext
### Get-ConfigurationConstraints

Analyse les contraintes d'un fichier de configuration.

```powershell
Get-ConfigurationConstraints -Path "config.json"
Get-ConfigurationConstraints -Path "config.json" -SchemaPath "schema.json" -ValidateValues
```plaintext
## Exemples

Voir le dossier `Examples` pour des exemples d'utilisation du module.

## Tests

Le module inclut des tests unitaires Pester. Pour exécuter les tests :

```powershell
Invoke-Pester -Path ".\Tests"
```plaintext
## Formats de configuration pris en charge

- JSON : Fichiers JSON standard
- YAML : Fichiers YAML (nécessite le module PowerShell-Yaml)
- XML : Fichiers XML
- INI : Fichiers de configuration INI
- PSD1 : Fichiers de données PowerShell

## Licence

Ce module est distribué sous licence MIT.

## Auteur

EMAIL_SENDER_1 Team
