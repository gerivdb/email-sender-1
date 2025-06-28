# Documentation Technique et Guides pour les Améliorations de `read_file`

Ce document fournit la documentation technique et les guides d'utilisation pour les améliorations apportées à la fonction `read_file`, incluant la lecture par plage, la navigation par bloc, la détection de fichiers binaires, et l'intégration avec VSCode.

## Table des Matières
1. [Introduction](#1-introduction)
2. [API Refactorisée (`pkg/common/read_file.go`)](#2-api-refactorisée-pkgcommonread_filego)
    - [ReadFileRange](#readfilerange)
    - [IsBinaryFile](#isbinaryfile)
    - [PreviewHex](#previewhex)
3. [CLI de Navigation (`cmd/read_file_navigator/read_file_navigator.go`)](#3-cli-de-navigation-cmdread_file_navigatorread_file_navigatorgo)
    - [Utilisation](#utilisation)
    - [Exemples](#exemples)
4. [Intégration VSCode (`scripts/vscode_read_file_selection.js`)](#4-intégration-vscode-scriptsvscode_read_file_selectionjs)
    - [Installation](#installation)
    - [Utilisation](#utilisation-1)
5. [Gestion des Fichiers Volumineux](#5-gestion-des-fichiers-volumineux)
6. [Tests et Validation](#6-tests-et-validation)
7. [Contribution](#7-contribution)

---

## 1. Introduction
Les améliorations de `read_file` visent à optimiser la manipulation de fichiers volumineux, en offrant des fonctionnalités de lecture par plage, de navigation interactive et une meilleure gestion des fichiers binaires. Ces outils sont conçus pour être performants et s'intégrer facilement dans l'environnement de développement.

## 2. API Refactorisée (`pkg/common/read_file.go`)

### `ReadFileRange(path string, startLine, endLine int) ([]string, error)`
Lit une plage spécifique de lignes d'un fichier. `startLine` et `endLine` sont inclusifs et basés sur 1.
- `path`: Chemin complet vers le fichier.
- `startLine`: Numéro de la première ligne à lire.
- `endLine`: Numéro de la dernière ligne à lire.
- **Retourne**: Un slice de chaînes de caractères, chaque chaîne représentant une ligne du fichier dans la plage spécifiée. Une erreur est retournée si le fichier ne peut pas être ouvert ou si la plage est invalide.

```go
// Exemple d'utilisation
lines, err := common.ReadFileRange("my_log_file.log", 10, 20)
if err != nil {
    fmt.Println("Erreur:", err)
} else {
    for _, line := range lines {
        fmt.Println(line)
    }
}
```

### `IsBinaryFile(path string) (bool, error)`
Détermine si un fichier est binaire en analysant un échantillon de son contenu.
- `path`: Chemin complet vers le fichier.
- **Retourne**: `true` si le fichier est probablement binaire, `false` sinon. Retourne également une erreur en cas de problème de lecture.

```go
// Exemple d'utilisation
isBinary, err := common.IsBinaryFile("my_image.jpg")
if err != nil {
    fmt.Println("Erreur:", err)
} else if isBinary {
    fmt.Println("Le fichier est binaire.")
} else {
    fmt.Println("Le fichier est un fichier texte.")
}
```

### `PreviewHex(path string, offset, length int) ([]byte, error)`
Lit une section spécifiée d'un fichier et retourne son contenu en format hexadécimal.
- `path`: Chemin complet vers le fichier.
- `offset`: Position de début (en octets) à partir de laquelle lire.
- `length`: Nombre d'octets à lire.
- **Retourne**: Un slice d'octets représentant le contenu hexadécimal. Retourne une erreur en cas de problème.

```go
// Exemple d'utilisation
hexData, err := common.PreviewHex("my_executable.exe", 0, 16)
if err != nil {
    fmt.Println("Erreur:", err)
} else {
    fmt.Printf("Contenu hexadécimal: %s\n", hexData)
}
```

## 3. CLI de Navigation (`cmd/read_file_navigator/read_file_navigator.go`)
Cet outil permet de naviguer et d'afficher le contenu de fichiers volumineux par blocs depuis la ligne de commande.

### Utilisation
```bash
go run cmd/read_file_navigator/read_file_navigator.go --file <chemin_fichier> --action <action> [options]
```

- `--file <chemin_fichier>`: **Obligatoire**. Le chemin vers le fichier à lire.
- `--action <action>`: L'action à effectuer. Peut être `first`, `next`, `prev`, `goto`, `start`, `end`. (Par défaut: `first`)
- `--block-size <taille_bloc>`: La taille du bloc en lignes pour la navigation. (Par défaut: `50`)
- `--block <numéro_bloc>`: Le numéro du bloc cible pour l'action `goto`. (Par défaut: `1`)

### Exemples
- Afficher le premier bloc de 10 lignes du fichier `logs.txt`:
    ```bash
    go run cmd/read_file_navigator/read_file_navigator.go --file logs.txt --action first --block-size 10
    ```
- Afficher le bloc 5 du fichier `data.csv` avec une taille de bloc par défaut:
    ```bash
    go run cmd/read_file_navigator/read_file_navigator.go --file data.csv --action goto --block 5
    ```
- Afficher le dernier bloc du fichier `report.log`:
    ```bash
    go run cmd/read_file_navigator/read_file_navigator.go --file report.log --action end
    ```

## 4. Intégration VSCode (`scripts/vscode_read_file_selection.js`)
Cette extension permet d'analyser une sélection de texte directement depuis VSCode en utilisant les outils Go développés.

### Installation
1. Copiez le fichier `scripts/vscode_read_file_selection.js` dans un nouveau répertoire `my-vscode-extension` (ou un nom similaire).
2. Créez un fichier `package.json` dans ce même répertoire avec le contenu suivant:
    ```json
    {
      "name": "read-file-analyzer",
      "displayName": "Read File Analyzer",
      "description": "Analyze selected text using Go CLI tools.",
      "version": "0.0.1",
      "engines": {
        "vscode": "^1.80.0"
      },
      "categories": [
        "Other"
      ],
      "activationEvents": [
        "onCommand:extension.analyzeSelection"
      ],
      "main": "./vscode_read_file_selection.js",
      "contributes": {
        "commands": [
          {
            "command": "extension.analyzeSelection",
            "title": "Read File: Analyze Selection"
          }
        ]
      }
    }
    ```
3. Dans VSCode, allez dans la vue Extensions (Ctrl+Shift+X).
4. Cliquez sur les trois points `...` en haut de la barre latérale des extensions.
5. Sélectionnez "Installer depuis VSIX..." et choisissez le fichier `my-vscode-extension.vsix` (que vous devrez créer en packagant votre extension si ce n'est pas déjà fait, ou utilisez "Installer une extension de dossier VSIX" si disponible).
   Alternativement, pour le développement, vous pouvez utiliser "Ouvrir le dossier d'extension" et sélectionner le répertoire `my-vscode-extension`.

### Utilisation
1. Ouvrez un fichier dans VSCode.
2. Sélectionnez une portion de texte.
3. Ouvrez la palette de commandes (Ctrl+Shift+P).
4. Tapez "Read File: Analyze Selection" et sélectionnez la commande.
5. Les résultats de l'analyse (effectuée par la CLI Go) apparaîtront dans un nouveau panneau de sortie.

## 5. Gestion des Fichiers Volumineux
Les fonctions de l'API `pkg/common/read_file.go` sont conçues pour gérer efficacement les fichiers volumineux en lisant uniquement les portions nécessaires ou en utilisant des tampons (buffers) pour éviter de charger l'intégralité du fichier en mémoire.

## 6. Tests et Validation
- **Tests Unitaires**: Les tests unitaires pour `pkg/common/read_file.go` couvrent les cas de lecture par plage, détection binaire et prévisualisation hexadécimale.
- **Tests d'Intégration**: Le fichier `integration/read_file_integration_test.go` contient des tests pour la CLI de navigation et des placeholders pour l'intégration VSCode et la gestion des fichiers volumineux.
- **Couverture de Code**: L'objectif est une couverture de code minimale de 85% pour les modules critiques. Un rapport de couverture HTML est généré automatiquement.

## 7. Contribution
Pour contribuer à ces améliorations, veuillez suivre les conventions de nommage et les standards de code définis dans le `plan_ameliorations_read_file.md` principal. Créez une branche de fonctionnalité, implémentez vos changements avec des tests, et soumettez une Pull Request pour revue.

---
