# Orchestrator Scanner

Ce script Go parcourt récursivement le répertoire courant pour identifier les fichiers contenant des motifs d'observabilité (logger, metric, report). Il génère ensuite un fichier Markdown (`manager_inventory.md`) et un fichier JSON (`event_hooks.json`) contenant les informations collectées.

## Usage

1.  Assurez-vous d'avoir Go installé sur votre système.
2.  Clonez ce dépôt.
3.  Exécutez le script :

    ```bash
    go run tools/orchestrator-scanner/main.go
    ```

4.  Les résultats seront enregistrés dans les fichiers `manager_inventory.md` et `event_hooks.json`.

## Configuration

Le script peut être configuré en modifiant les valeurs par défaut dans la fonction `DefaultScannerConfig` du fichier `main.go`. Les options de configuration incluent :

*   `ExcludeDirs`: Liste des répertoires à exclure de la recherche.
*   `MaxFileSize`: Taille maximale des fichiers à analyser (en octets).
*   `MaxDepth`: Profondeur maximale de la récursion.
*   `OutputFileMD`: Nom du fichier Markdown de sortie.
*   `OutputFileJSON`: Nom du fichier JSON de sortie.

## Exemple de sortie

**manager\_inventory.md:**

```markdown
# Inventaire des sources d'observabilité

\- \*\*main.go\*\* (logger): package main import ( "log" ) func main() { log.Println("test") }...
```

**event\_hooks.json:**

```json
\[
  {
    "path": "main.go",
    "type": "logger",
    "content_snippet": "package main import ( \\"log\\" ) func main() { log.Println(\\"test\\") }..."
  }
]
```

## Tests unitaires

Pour exécuter les tests unitaires, utilisez la commande suivante :

```bash
go test tools/orchestrator-scanner/main.go tools/orchestrator-scanner/main_test.go
```

## Intégration CI/CD

Ce script peut être intégré dans un pipeline CI/CD pour générer automatiquement l'inventaire des sources d'observabilité à chaque commit.