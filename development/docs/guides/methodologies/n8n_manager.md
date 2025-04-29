# Guide du Gestionnaire N8n Manager

## Introduction

Le gestionnaire N8n Manager est un composant essentiel du systÃ¨me qui gÃ¨re les fonctionnalitÃ©s liÃ©es Ã  n8n manager. Ce document dÃ©taille son fonctionnement, ses paramÃ¨tres, et fournit des exemples d'utilisation pour vous aider Ã  l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire N8n Manager est de fournir des fonctionnalitÃ©s liÃ©es Ã  n8n manager. Il permet notamment de :

- Gestion des fonctionnalitÃ©s liÃ©es Ã  n8n manager
- Configuration et personnalisation du gestionnaire
- IntÃ©gration avec d'autres gestionnaires
- Journalisation et surveillance des activitÃ©s

## Architecture

### Structure des rÃ©pertoires

Le gestionnaire N8n Manager est organisÃ© selon la structure de rÃ©pertoires suivante :

```
development/managers/n8n-manager/
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ n8n-manager.ps1           # Script principal
â”‚   â”œâ”€â”€ install-n8n-manager.ps1   # Script d'installation (si applicable)
â”‚   â””â”€â”€ ...                                 # Autres scripts
â”œâ”€â”€ modules/
â”‚   â””â”€â”€ ...                                 # Modules PowerShell
â”œâ”€â”€ tests/
â”‚   â”œâ”€â”€ Test-[NomDuGestionnaire].ps1        # Tests unitaires
â”‚   â””â”€â”€ ...                                 # Autres tests
â””â”€â”€ config/
    â””â”€â”€ ...                                 # Fichiers de configuration locaux
```

### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockÃ©s dans :

```
projet/config/managers/n8n-manager/
â””â”€â”€ n8n-manager.config.json       # Configuration principale
```

## PrÃ©requis

Avant d'utiliser le gestionnaire N8n Manager, assurez-vous que :

1. PowerShell 5.1 ou supÃ©rieur est installÃ© sur votre systÃ¨me
2. Le gestionnaire intÃ©grÃ© est installÃ©
3. Les droits d'accÃ¨s appropriÃ©s sont configurÃ©s

## Installation

### Installation automatique

Pour installer le gestionnaire N8n Manager, utilisez le script d'installation :

```powershell
.\development\managers\n8n-manager\scripts\install-n8n-manager.ps1
```

### Installation manuelle

Si vous prÃ©fÃ©rez une installation manuelle, suivez ces Ã©tapes :

1. Copiez les fichiers du gestionnaire dans le rÃ©pertoire appropriÃ©
2. CrÃ©ez le fichier de configuration dans le rÃ©pertoire appropriÃ©
3. VÃ©rifiez que le gestionnaire fonctionne correctement

## Configuration

### Fichier de configuration principal

Le fichier de configuration principal du gestionnaire est situÃ© Ã  :

```
projet/config/managers/n8n-manager/n8n-manager.config.json
```

Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "Parameters": {
    "Parameter1": "Value1",
    "Parameter2": "Value2"
  },
  "Paths": {
    "LogPath": "logs/n8n-manager",
    "DataPath": "data/n8n-manager"
  }
}
```

### Options de configuration

| Option | Type | Description | Valeur par dÃ©faut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou dÃ©sactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| Parameters | object | ParamÃ¨tres spÃ©cifiques au gestionnaire | {} |
| Paths | object | Chemins utilisÃ©s par le gestionnaire | {} |

## Utilisation

### Commandes principales

Le gestionnaire N8n Manager expose les commandes suivantes :

#### Commande 1 : [NOM_COMMANDE_1]

```powershell
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE_1] -Parameter1 Value1 -Parameter2 Value2
```

**Description :** [DESCRIPTION_COMMANDE_1]

**ParamÃ¨tres :**
- `-Parameter1` : [DESCRIPTION_PARAMÃˆTRE_1]
- `-Parameter2` : [DESCRIPTION_PARAMÃˆTRE_2]

**Exemple :**
```powershell
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE_1] -Parameter1 "Exemple" -Parameter2 10
```

#### Commande 2 : [NOM_COMMANDE_2]

```powershell
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE_2] -Parameter3 Value3
```

**Description :** [DESCRIPTION_COMMANDE_2]

**ParamÃ¨tres :**
- `-Parameter3` : [DESCRIPTION_PARAMÃˆTRE_3]

**Exemple :**
```powershell
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE_2] -Parameter3 "Exemple"
```

### Exemples d'utilisation

#### Exemple 1 : [TITRE_EXEMPLE_1]

```powershell
# [DESCRIPTION_EXEMPLE_1]
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE] -Parameter1 "Valeur1" -Parameter2 "Valeur2"
```

#### Exemple 2 : [TITRE_EXEMPLE_2]

```powershell
# [DESCRIPTION_EXEMPLE_2]
.\development\managers\n8n-manager\scripts\n8n-manager.ps1 -Command [NOM_COMMANDE] -Parameter3 "Valeur3"
```

## IntÃ©gration avec d'autres gestionnaires

Le gestionnaire N8n Manager s'intÃ¨gre avec les autres gestionnaires du systÃ¨me :

### IntÃ©gration avec le gestionnaire intÃ©grÃ©

```powershell
# Utiliser le gestionnaire N8n Manager via le gestionnaire intÃ©grÃ©
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Manager N8n Manager -Command [NOM_COMMANDE] -Parameter1 "Valeur1"
```

### IntÃ©gration avec le gestionnaire de modes

```powershell
# Utiliser le gestionnaire N8n Manager via le gestionnaire de modes
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Mode [NOM_MODE] -UseManager N8n Manager -Command [NOM_COMMANDE]
```

## DÃ©pannage

### ProblÃ¨mes courants et solutions

#### ProblÃ¨me 1 : [TITRE_PROBLÃˆME_1]

**SymptÃ´mes :**
- [SYMPTÃ”ME_1]
- [SYMPTÃ”ME_2]

**Causes possibles :**
- [CAUSE_1]
- [CAUSE_2]

**Solutions :**
1. [SOLUTION_1]
2. [SOLUTION_2]

#### ProblÃ¨me 2 : [TITRE_PROBLÃˆME_2]

**SymptÃ´mes :**
- [SYMPTÃ”ME_1]
- [SYMPTÃ”ME_2]

**Causes possibles :**
- [CAUSE_1]
- [CAUSE_2]

**Solutions :**
1. [SOLUTION_1]
2. [SOLUTION_2]

### Journalisation

Le gestionnaire N8n Manager gÃ©nÃ¨re des journaux dans le rÃ©pertoire suivant :

```
logs/n8n-manager/
```

Les niveaux de journalisation peuvent Ãªtre configurÃ©s dans le fichier de configuration principal.

## Tests

### ExÃ©cution des tests

Pour exÃ©cuter les tests du gestionnaire N8n Manager, utilisez la commande suivante :

```powershell
.\development\managers\n8n-manager\tests\Test-[NomDuGestionnaire].ps1
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intÃ©gration :** Testent l'intÃ©gration avec d'autres composants
- **Tests de performance :** Ã‰valuent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire intÃ©grÃ© pour accÃ©der Ã  ce gestionnaire lorsque c'est possible
2. Configurez correctement le fichier de configuration avant d'utiliser le gestionnaire
3. Consultez les journaux en cas de problÃ¨me

### SÃ©curitÃ©

1. N'exÃ©cutez pas le gestionnaire avec des privilÃ¨ges administrateur sauf si nÃ©cessaire
2. ProtÃ©gez l'accÃ¨s aux fichiers de configuration
3. Utilisez des mots de passe forts pour les services associÃ©s

## RÃ©fÃ©rences

- [Documentation du gestionnaire intÃ©grÃ©](integrated_manager.md)
- [Documentation du gestionnaire de modes](mode_manager.md)
- [Guide des bonnes pratiques](../best-practices/powershell_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
