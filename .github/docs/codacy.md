# Utilisation de Codacy dans ce projet

## Analyse statique et sécurité

Ce projet utilise Codacy CLI pour l’analyse statique du code et la détection des vulnérabilités de dépendances. L’intégration se fait via des tâches automatisées et des scripts, sans installation manuelle de la CLI.

### Lancer une analyse Codacy sur un fichier spécifique

Utilisez la tâche VS Code suivante :

```sh
java -jar "C:/Program Files/CodacyCLI/codacy-analysis-cli-assembly.jar" analyze --directory . --files <chemin/vers/fichier.go> --output result-<nom>.json
```

### Lancer une analyse de sécurité (Trivy)

Pour vérifier les dépendances :

```sh
java -jar "C:/Program Files/CodacyCLI/codacy-analysis-cli-assembly.jar" analyze --tool trivy --directory . --output trivy-results.json
```

### Bonnes pratiques
- Toujours lancer une analyse Codacy après modification d’un fichier Go ou d’un fichier de dépendances (`go.mod`, `go.sum`, etc.).
- Corriger les problèmes signalés avant de committer.
- Ne jamais installer Codacy CLI manuellement : elle est déjà disponible sur l’environnement CI/CD et en local (Windows, chemin par défaut).

### Intégration CI/CD
L’analyse Codacy est intégrée dans les workflows CI/CD pour garantir la qualité et la sécurité du code avant chaque merge.

### Répertoire de sortie
Les résultats sont générés dans des fichiers `result-*.json` ou `trivy-results.json` à la racine du projet.

---

Pour toute question ou problème avec Codacy, contacter l’équipe DevOps ou consulter la documentation officielle : https://docs.codacy.com/codacy-analysis-cli/
