# Spécifications des Rapports de Dépendances

Ce document décrit les besoins et les formats attendus pour les rapports de dépendances Go générés par le système.

## Contenu du Rapport

Le rapport doit inclure les informations suivantes pour chaque dépendance :

- **Nom du Module (Path)** : Chemin complet du module (ex: `github.com/gin-gonic/gin`).
- **Version** : Version du module (ex: `v1.10.1`).
- **Statut (Main/Indirect)** : Indique si le module est une dépendance directe (`main`) ou indirecte (`indirect`).
- **Chemin Local (Dir)** : Chemin absolu du module sur le système de fichiers local.
- **Fichier go.mod du module (GoMod)** : Chemin vers le fichier `go.mod` du module s'il existe.
- **Licence** : Type de licence (ex: MIT, Apache 2.0). (À implémenter dans une phase ultérieure)
- **Vulnérabilités** : Liste des vulnérabilités connues associées au module. (À implémenter dans une phase ultérieure, via `govulncheck` ou `snyk`)

## Formats de Sortie

Les rapports doivent être générés dans les formats suivants :

- **JSON** : Pour l'intégration machine et l'analyse automatisée.
  - Structure JSON:
    ```json
    {
      "timestamp": "YYYY-MM-DD_HH-MM-SS",
      "dependencies": [
        {
          "Path": "...",
          "Version": "...",
          "Main": true/false,
          "Indirect": true/false,
          "Dir": "...",
          "GoMod": "..."
        }
      ],
      "summary": "Report generated for X dependencies."
    }
    ```
- **Markdown (.md)** : Pour une lecture humaine facile.
  - Formatage Markdown:
    ```markdown
    # Rapport des dépendances Go - YYYY-MM-DD_HH-MM-SS

    ## Résumé

    Report generated for X dependencies.

    ## Dépendances

    - `github.com/gin-gonic/gin` v1.10.1 (module principal)
      - Répertoire: `/path/to/module`
      - Fichier go.mod: `/path/to/module/go.mod`
    - `golang.org/x/text` v0.3.0 (indirect)
    ...
    ```
- **SVG (Graphique)** : Représentation visuelle du graphe des dépendances. (À implémenter dans une phase ultérieure, en utilisant `go mod graph` et un outil de rendu comme Graphviz)

## Fréquence de Génération

Les rapports doivent être générés :

- À chaque push sur la branche `main`.
- Quotidiennement via une tâche CI/CD nocturne.

## Intégration CI/CD

Le processus de génération de rapports doit être intégré dans le pipeline CI/CD existant, avec des échecs de build en cas d'erreurs critiques (par exemple, impossibilité de générer le rapport).
